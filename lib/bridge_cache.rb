require 'bridge_pender'
require 'bridge_cc_deville'
require 'chromeshot'

module Bridge
  module Cache
    def clear_cache(project, collection, item)
      FileUtils.rm_rf(cache_path(project, collection, item))
      FileUtils.rm_rf(cache_path(project, collection, item, 'screenshot'))
      notify_cc_service(project, collection, item)
      true
    end

    def cache_path(project, collection, item, template = '')
      self.file_path(project, collection, item, 'cache', 'html', template)
    end

    def cache_exists?(project, collection, item, template = '')
      File.exists?(cache_path(project, collection, item, template))
    end

    def screenshot_exists?(project, collection, item, css = '')
      File.exists?(screenshot_path(project, collection, item, css))
    end

    def generate_cache(object, collection, item, template = '')
      # Check first if item exists
      return if object.nil?
      project = object.project
      level = get_level(project, collection, item)
      @source_entries = get_entries_from_source(object, collection, item, template)
      if @source_entries.blank?
        clear_cache(project, collection, item) if template.blank?
        return false
      end
      path = cache_path(project, collection, item, template)
      new_item = !File.exists?(path)
      save_cache_file(object, collection, item, template)
      if template.blank?
        object.notify_new_item(collection, item, new_item)
        notify_cc_service(project, collection, item)
      end
      true
    end

    def remove_screenshot(project, collection, item)
      path = screenshot_path(project, collection, item)
      path_with_css = path.gsub(item, "#{item}-*")
      Dir.glob([path, path_with_css]).each { |f| FileUtils.rm_rf(f) }
      notify_cc_service(project, collection, item, 'png')
    end

    def screenshot_path(project, collection, item, css = '')
      css = Digest::MD5.hexdigest(css.parameterize) unless css.blank?
      self.file_path(project, collection, item, 'screenshots', 'png', '', css)
    end

    def generate_screenshot(project, collection, item, css = '')
      output = screenshot_path(project, collection, item, css)
      if BRIDGE_CONFIG['cache_embeds'] && File.exists?(output)
        # Cache file will be returned
      else
        url = self.screenshot_url(project, collection, item, css)
        level = self.get_level(project, collection, item)
        self.take_screenshot(url, output, level)
      end
      output
    end

    def notify_cc_service(project, collection, item, format = nil)
      return if BRIDGE_CONFIG['cc_deville_host'].blank?
      url = [BRIDGE_CONFIG['bridgembed_host'], 'medias', 'embed', project, URI.encode(collection), item].reject{ |part| part.blank? }.join('/')
      url += '.' + format unless format.blank?
      cc = Bridge::CcDeville.new(BRIDGE_CONFIG['cc_deville_host'], BRIDGE_CONFIG['cc_deville_token'], BRIDGE_CONFIG['cc_deville_httpauth'])
      cc.clear_cache(url)
    end

    protected

    def get_level(project, collection, item)
      if !item.blank?
        'item'
      elsif !collection.blank?
        'collection'
      else
        'project'
      end
    end

    def get_entries_from_source(object, collection, item, template = '')
      level = get_level(object.project, collection, item)
      pender = Bridge::Pender.new BRIDGE_CONFIG['pender_token']
      entries = {}.with_indifferent_access
      level_mapping(level, template).each do |l|
        entries[l] = pender.send("parse_#{l}", object.send("get_#{l}", collection, item))
      end
      entries[level].blank? ? [] : entries
    end

    def level_mapping(level, template)
      mapping = {
        'project' => [:project],
        'collection' => [:project, :collection],
        'item' => [:project, :collection, :item],
      }
      template.blank? ? mapping[level] : [:item]
    end

    def save_cache_file(object, collection, item, template_name = '')
      project = object.project
      level = get_level(object.project, collection, item)
      cache_path = cache_path(project, collection, item, template_name)
      dir = File.dirname(cache_path)
      FileUtils.mkdir_p(dir) unless File.exists?(dir)

      path = self.get_components(project, collection, item, template_name).join('-')
      av = ActionView::Base.new(Rails.root.join('app', 'views'))
      av.assign(entries: @source_entries, project: project, collection: collection,
                item: item, level: level, path: path)
      ActionView::Base.send :include, MediasHelper
      template = template_name.blank? ? "medias/embed-#{level}.html.erb" : "medias/#{template_name}-#{level}.html.erb"
      content = av.render(template: template, layout: "layouts/application.html.erb")
      File.atomic_write(cache_path) do |file|
        file.write(content)
      end
    end

    def screenshot_url(project, collection, item, css = '')
      url = [BRIDGE_CONFIG['bridgembed_host'], 'medias', 'embed', project, URI.encode(collection), item].join('/') + "?&template=screenshot"
      url += "#css=#{css}" unless css.blank?
      url
    end

    def get_components(project, collection, item, template)
      [template.to_s, project, collection, item].reject(&:empty?)
    end

    def file_path(project, collection, item, basedir, extension, template = '', css = '')
      item = [item, css].compact.join('-') unless item.blank? || css.blank?
      path = self.get_components(project, collection, item, template)
      File.join(Rails.root, 'public', basedir, path) + '.' + extension
    end

    def take_screenshot(url, output, level)
      FileUtils.mkdir_p(File.dirname(output))
      tmp = Tempfile.new(['screenshot', '.png']).path
      result = request_url(url)
      return false unless result && verify_screenshot(result)
      screenshot = result['data']['screenshot']
      open(screenshot) do |f|
        File.atomic_write(tmp) { |file| file.write(f.read) }
      end
      fetcher = Chromeshot::Screenshot.new debug_port: BRIDGE_CONFIG['chrome_debug_port']
      level === 'item' ? fetcher.post_process_screenshot(original: tmp, output: output, proportion: 2) : FileUtils.cp(tmp, output)
    end

    def request_url(url)
      params = { url: url }
      result = PenderClient::Request.get_medias(BRIDGE_CONFIG['pender_base_url'], params, BRIDGE_CONFIG['pender_token'])
      return unless result['data'].has_key?('screenshot')
      attempts = 0
      while attempts < 30 && result['data']['screenshot_taken'].to_i == 0
        sleep 10
        attempts += 1
        params[:url] = result['data']['url'] if result['data'] && result['data']['url']
        result = PenderClient::Request.get_medias(BRIDGE_CONFIG['pender_base_url'], params, BRIDGE_CONFIG['pender_token'])
      end
      result
    end

    def verify_screenshot(result)
      return true if result['data']['screenshot_taken'].to_i > 0
      Airbrake.notify("No screenshot received, response was: #{result.inspect}") if Airbrake.configuration.api_key
      false
    end
  end
end
