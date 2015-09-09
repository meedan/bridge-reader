require 'bridge_embedly'
require 'bridge_cc_deville'
require 'smartshot'

module Bridge
  module Cache
    def clear_cache(project, collection, item)
      FileUtils.rm_rf(cache_path(project, collection, item))
      notify_cc_service(project, collection, item)
    end

    def cache_path(project, collection, item)
      self.file_path(project, collection, item, 'cache', 'html')
    end

    def cache_exists?(project, collection, item)
      File.exists?(cache_path(project, collection, item))
    end

    def screenshot_exists?(project, collection, item)
      File.exists?(screenshot_path(project, collection, item))
    end

    def generate_cache(object, project, collection, item, site = BRIDGE_CONFIG['bridgembed_host'])
      # Check first if item exists
      level = get_level(project, collection, item)
      entries = get_entries_from_source(object, collection, item, level)
      return if entries.blank?

      path = cache_path(project, collection, item)
      dir = File.dirname(path)
      FileUtils.mkdir_p(dir) unless File.exists?(dir)
      new_item = !File.exists?(path)
      save_cache_file(object, project, collection, item, level, entries, site)
      object.notify_new_item(collection, item) if new_item
      notify_cc_service(project, collection, item)
    end

    def remove_screenshot(project, collection, item)
      FileUtils.rm_rf(screenshot_path(project, collection, item))
      notify_cc_service(project, collection, item, 'png')
    end

    def screenshot_path(project, collection, item)
      self.file_path(project, collection, item, 'screenshots', 'png')
    end

    def screenshoter
      path = File.join(Rails.root, 'bin', 'phantomjs-' + (1.size * 8).to_s)
      version = `#{path} --version`
      if (version.chomp =~ /^[0-9.]+$/).nil?
        path = `which phantomjs`
        version = `#{path.chomp} --version`
      end

      raise 'PhantomJS not found!' if (version.chomp =~ /^[0-9.]+$/).nil?

      options = { phantomjs: path.chomp, timeout: 40 }

      if Rails.env.test?
        options.merge! run_server: true
      end

      Smartshot::Screenshot.new(options)
    end

    def generate_screenshot(project, collection, item, css = '')
      output = screenshot_path(project, collection, item)
      if BRIDGE_CONFIG['cache_embeds'] && File.exists?(output)
        # Cache file will be returned
      else
        url = self.screenshot_url(project, collection, item, css)
        
        frames = []
        element = ['body']
        link = Rails.cache.read('embedly:' + item)

        unless link.nil?
          case link[:provider]
          when 'twitter'
            frames  = [0]
            element = ['.twitter-tweet-rendered']
          when 'instagram'
            frames  = [0]
            element = ['img.art-bd-img']
          end
        end

        self.take_screenshot(url, element, frames, output)
      end
      output
    end

    def take_screenshot(url, element, frames, output)
      FileUtils.mkdir_p(File.dirname(output))
      tmp = Tempfile.new(['screenshot', '.png']).path
      screenshoter.take_screenshot!(url: url, output: tmp, wait_for_element: element, frames_path: frames, sleep: 20)
      FileUtils.cp(tmp, output)
      FileUtils.rm(tmp)
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

    def get_entries_from_source(object, collection, item, level)
      embedly = Bridge::Embedly.new BRIDGE_CONFIG['embedly_key']
      entries = object.send("get_#{level}", collection, item)
      entries.blank? ? [] : embedly.send("parse_#{level}", entries)
    end

    def save_cache_file(object, project, collection, item, level, entries, site = nil)
      path = self.get_components(project, collection, item).join('-')
      av = ActionView::Base.new(Rails.root.join('app', 'views'))
      av.assign(entries: entries, project: project, collection: collection,
                item: item, site: site, level: level, path: path)
      ActionView::Base.send :include, MediasHelper
      f = File.new(cache_path(project, collection, item), 'w+')
      f.puts(av.render(template: "medias/embed-#{level}.html.erb", layout: "layouts/application.html.erb"))
      f.close
    end

    def screenshot_url(project, collection, item, css = '')
      url = [BRIDGE_CONFIG['bridgembed_host_private'], 'medias', 'embed', project, URI.encode(collection), item].join('/') + "?#{Time.now.to_i}"
      url += "#css=#{css}" unless css.blank?
      url
    end

    def get_components(project, collection, item)
      [project, collection, item].reject(&:empty?)
    end

    def file_path(project, collection, item, basedir, extension)
      path = self.get_components(project, collection, item)
      File.join(Rails.root, 'public', basedir, path) + '.' + extension
    end
  end
end
