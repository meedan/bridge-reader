module Bridge
  module Cache
    def cache_dir
      File.join(Rails.root, 'public', 'cache')
    end

    def clear_cache(type, id)
      FileUtils.rm(cache_path(type, id))
    end

    def cache_path(type, id)
      File.join(cache_dir, type, "#{id}.html")
    end

    # The old cache path until Bridgembed 0.5
    # Deprecated - please remove it later
    def legacy_cache_path(id)
      Dir.glob(File.join(cache_dir, "#{id}_*")).first
    end

    def generate_cache(object, type, id, site = nil)
      FileUtils.mkdir(cache_dir) unless File.exists?(cache_dir)
      FileUtils.mkdir(File.join(cache_dir, type)) unless File.exists?(File.join(cache_dir, type))
      should_send_to_watchbot = !File.exists?(cache_path(type, id))
      remove_screenshot(type, id)
      save_cache_file(object, type, id, site)
      object.send_to_watchbot if should_send_to_watchbot 
    end

    def bridge_cache_key(entry)
      hash = Digest::SHA1.hexdigest(entry.except(:source).to_s)
      entry[:link] + ':' + hash
    end

    def remove_screenshot(type, id)
      FileUtils.rm_rf(screenshot_path(type, id))
    end

    def screenshot_path(type, id)
      File.join(Rails.root, 'public', 'screenshots', type, "#{id}.png")
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

    def generate_screenshot(type, id, css = '')
      output = screenshot_path(type, id)
      if File.exists?(output)
        output
      else
        require 'smartshot'
        url = URI.join(BRIDGE_CONFIG['bridgembed_host_private'], 'medias/', 'embed/', type + '/', id, "#css=#{css}")
        
        frames = []
        element = ['body']
        link = Rails.cache.read(id)

        unless link.nil?
          case URI.parse(link[:url]).host
          when 'twitter.com'
            frames  = [0, 'twitter-widget-0']
            element = ['.EmbeddedTweet-tweet img.Avatar:last-child']
          when 'instagram.com'
            frames  = [0]
            element = ['img.art-bd-img']
          end
        end

        screenshoter.take_screenshot!(url: url, output: output, wait_for_element: element, frames_path: frames, sleep: 5) ? output : nil
      end
    end

    protected

    def save_cache_file(object, type, id, site = nil)
      embedly = Bridge::Embedly.new BRIDGE_CONFIG['embedly_key']
      av = ActionView::Base.new(Rails.root.join('app', 'views'))
      av.assign(entries: embedly.parse_entries(object.get_entries), type: type, id: id, site: site)
      ActionView::Base.send :include, MediasHelper
      f = File.new(cache_path(type, id), 'w+')
      f.puts(av.render(template: 'medias/embed.html.erb'))
      f.close
    end
  end
end
