require 'bridge_cache'
require 'bridge_error_codes'

class MediasController < ApplicationController
  include Bridge::Cache

  after_action :allow_iframe, only: :embed
  before_filter :get_params, only: [:embed, :notify]
  before_filter :get_host
  before_filter :set_headers

  def embed
    respond_to do |format|
      format.html { render_embed_as_html           }
      format.js   { render_embed_as_js             }
      format.png  { render_embed_as_png and return }
    end
  end

  def notify
    begin
      payload = request.raw_post
      if verify_signature(payload)
        get_object and return
        @object.parse_notification(@collection, @item, JSON.parse(payload))
        render_success
      else
        render_error 'Signature could not be verified', 'INVALID_SIGNATURE'
      end
    rescue Exception => e
      render_error e.message, 'EXCEPTION'
    end
  end

  private

  def render_embed_as_png
    html = cache_path(@project, @collection, @item)

    unless File.exists?(html)
      get_object and return
      generate_cache(@object, @project, @collection, @item, @site)
    end

    if File.exists?(html)
      css = URI.parse(params[:css].to_s).to_s
      @image = generate_screenshot(@project, @collection, @item, css)
      send_data File.read(@image), type: 'image/png', disposition: 'inline'
    else
      render_error('Item not found (deleted, maybe?)', 'NOT_FOUND', 404)
    end
  end

  def render_embed_as_js
    @caller = request.original_url.gsub(/\?.*$/, '')
    @caller_path = request.fullpath.gsub(/\?.*$/, '')
    @url = @caller.gsub(/\.js.*$/, '')
    @path = [@project, @collection, @item].reject(&:blank?).join('-')
  end

  def render_embed_as_html
    @cachepath = cache_path(@project, @collection, @item)
    if BRIDGE_CONFIG['cache_embeds'] && File.exists?(@cachepath)
      @cache = true
    else
      get_object and return
      generate_cache(@object, @project, @collection, @item, @site)
      @cache = false
    end

    logger.info "Rendering cache file #{@cachepath}"

    if File.exists?(@cachepath)
      render text: File.read(@cachepath)
    else
      render_error('Item not found (deleted, maybe?)', 'NOT_FOUND', 404)
    end
  end

  def allow_iframe
    response.headers.except! 'X-Frame-Options'
  end

  def verify_signature(payload)
    signature = 'sha1=' + OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new('sha1'), BRIDGE_CONFIG['secret_token'].to_s, payload)
    Rack::Utils.secure_compare(signature, request.headers['X-Signature'].to_s)
  end

  def get_params
    BRIDGE_PROJECTS.keys.each do |project|
      @project = project if params[:project].to_s === project
    end
    
    sanitize_parameters(params[:collection], params[:item])

    (render_error('Project not found', 'NOT_FOUND', 404) and return) if @project.blank?
  end

  def get_object
    begin
      klass = 'Sources::' + BRIDGE_PROJECTS[@project]['type'].camelize
      @object = klass.constantize.new(@project, BRIDGE_PROJECTS[@project].except('type'))
    rescue NameError
      render_error('Type not found', 'NOT_FOUND', 404) and return true
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
end
