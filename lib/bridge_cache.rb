require 'bridge_embedly'

module Bridge
  module Cache
    def clear_cache(project, collection, item)
      FileUtils.rm(cache_path(project, collection, item))
    end

    def cache_path(project, collection, item)
      path = [project, collection, item].reject(&:empty?)
      File.join(Rails.root, 'public', 'cache', path) + '.html'
    end

    def cache_exists?(project, collection, item)
      File.exists?(cache_path(project, collection, item))
    end

    def screenshot_exists?(project, collection, item)
      File.exists?(screenshot_path(project, collection, item))
    end

    def generate_cache(object, project, collection, item, site = BRIDGE_CONFIG['bridgembed_host'])
      path = cache_path(project, collection, item)
      dir = File.dirname(path)
      FileUtils.mkdir_p(dir) unless File.exists?(dir)
      new_item = !File.exists?(path)
      save_cache_file(object, project, collection, item, site)
      object.notify_new_item(collection, item) if new_item
    end

    def remove_screenshot(project, collection, item)
      FileUtils.rm_rf(screenshot_path(project, collection, item))
    end

    def screenshot_path(project, collection, item)
      path = [project, collection, item].reject(&:empty?)
      File.join(Rails.root, 'public', 'screenshots', path) + '.png'
    end

    def screenshoter
      path = File.join(Rails.root, 'bin', 'phantomjs-' + (1.size * 8).to_s)
      version = `#{path} --version`
      if (version.chomp =~ /^[0-9.]+$/).nil?
        path = `which phantomjs`
      end

      raise 'PhantomJS not found!' if version.empty?

      options = { phantomjs: path.chomp, timeout: 40 }

      if Rails.env.test?
        options.merge! run_server: true
      end

      Smartshot::Screenshot.new(options)
    end

    def generate_screenshot(project, collection, item, css = '')
      output = screenshot_path(project, collection, item)
      if File.exists?(output)
        output
      else
        require 'smartshot'
        url = [BRIDGE_CONFIG['bridgembed_host_private'], 'medias', 'embed', project, collection, item].join('/')
        url += "?#{Time.now.to_i}#css=#{css}"
        
        frames = []
        element = ['body']
        link = Rails.cache.read('embedly:' + item)

        unless link.nil?
          case link[:provider]
          when 'twitter'
            frames  = [0, 'twitter-widget-0']
            element = ['.EmbeddedTweet-tweet img.Avatar:last-child']
          when 'instagram'
            frames  = [0]
            element = ['img.art-bd-img']
          end
        end

        screenshoter.take_screenshot!(url: url, output: output, wait_for_element: element, frames_path: frames, sleep: 5) ? output : nil
      end
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
      embedly.send("parse_#{level}", entries)
    end

    def save_cache_file(object, project, collection, item, site = nil)
      path = [project, collection, item].reject(&:empty?).join('-')
      level = get_level(project, collection, item)
      av = ActionView::Base.new(Rails.root.join('app', 'views'))
      av.assign(entries: get_entries_from_source(object, collection, item, level),
                project: project, collection: collection, item: item, site: site, level: level, path: path)
      ActionView::Base.send :include, MediasHelper
      f = File.new(cache_path(project, collection, item), 'w+')
      f.puts(av.render(template: "medias/embed-#{level}.html.erb", layout: "layouts/application.html.erb"))
      f.close
    end
  end
end
