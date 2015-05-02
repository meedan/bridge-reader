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

    def generate_screenshot(type, id)
      path = screenshot_path(type, id)
      if File.exists?(path)
        path
      else
        require 'screencap'
        url = URI.join(BRIDGE_CONFIG['bridgembed_host'], 'medias/', 'embed/', type + '/', id)
        fetcher = Screencap::Fetcher.new(url.to_s)
        screenshot = fetcher.fetch(output: path)
        screenshot.nil? ? nil : screenshot.path
      end
    end

    protected

    # def save_cache_file(milestone, worksheet, link = nil, site = nil)
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
