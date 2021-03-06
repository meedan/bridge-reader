module MediasFilters
  extend ActiveSupport::Concern

  private

  def generate_screenshot_image
    begin
      @image = generate_screenshot(@project, @collection, @item, @css)
    rescue Exception => e
      raise "Could not take screenshot: #{e.message}" unless from_bot?
    end
  end

  def from_bot?
    patterns = Rails.cache.fetch('bots-patterns', expire_in: 72.hours) do
      bots_patterns
    end
    regex = /#{patterns.join('|')}/i
    !regex.match(request.env['HTTP_USER_AGENT']).nil?
  end

  def bots_patterns
    patterns = []
    url = BRIDGE_CONFIG['crawlers'] || 'https://raw.githubusercontent.com/monperrus/crawler-user-agents/master/crawler-user-agents.json'
    uri = URI.parse(url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    request = Net::HTTP::Get.new(uri.request_uri)
    response = http.request(request)
    if response.code == "200"
      result = JSON.parse(response.body)
      patterns = result.collect{ |p| p['pattern'] }
    end
    patterns
  end

  def allow_iframe
    response.headers.except! 'X-Frame-Options'
  end

  def verify_signature(payload)
    signature = 'sha1=' + OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new('sha1'), BRIDGE_CONFIG['secret_token'].to_s, payload)
    unless Rack::Utils.secure_compare(signature, request.headers['X-Signature'].to_s)
      render_error 'Signature could not be verified', 'INVALID_SIGNATURE' and return true
    end
  end

  def get_params
    BRIDGE_PROJECTS.keys.each do |project|
      @project = project if params[:project].to_s === project
    end
    
    sanitize_parameters(params[:collection], params[:item])

    @css = URI.parse(params[:css].to_s).to_s
    @template = params[:template].to_s.gsub(/[^a-z0-9_-]/, '')
    (render_not_found and return) if @project.blank?
  end

  def get_object
    begin
      klass = 'Sources::' + BRIDGE_PROJECTS[@project]['type'].camelize
      @object = klass.constantize.new(@project, BRIDGE_PROJECTS[@project].except('type'))
    rescue NameError
      return nil
    end
    false
  end

  def get_host
    @host = request.host
    @host_with_port = request.host_with_port
    @protocol = request.protocol
    @site = @protocol + @host_with_port
  end

  def set_headers
    response.headers['Cache-Control'] = 'no-transform,public,max-age=600,s-maxage=300'
  end

  def sanitize_parameters(collection, item)
    @collection = params[:collection].to_s.gsub(/[^0-9A-Za-z_\-\u0600-\u06ff\u0750-\u077f\ufb50-\ufc3f\ufe70-\ufefc]/, '')
    @item = params[:item].to_s.gsub(/[^0-9A-Za-z_-]/, '')
  end

  def render_embed_from_template
    return if @template.blank?
    @level = get_level(@project, @collection, @item)
    template_name = "medias/#{@template}-#{@level}.html.erb"
    render_not_found and return true if !File.exists?(File.join(Rails.root, 'app', 'views', template_name))
    return false
  end

  def post_process_cache(content)
    content.gsub(/<meta content="[^"]+" property="og:url" \/>/, "<meta content=\"#{@url}\" property=\"og:url\" />")
  end
end
