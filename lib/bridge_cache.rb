module Bridge
  module Cache
    def cache_dir
      File.join(Rails.root, 'public', 'cache')
    end

    def clear_cache(milestone)
      FileUtils.rm Dir.glob(File.join(cache_dir, "#{milestone}.html"))
    end

    def cache_path(worksheet, link = nil)
      title = worksheet.is_a?(Bridge::GoogleSpreadsheet) ? worksheet.get_title : worksheet
      path = link.nil? ? File.join(cache_dir, "#{title}.html") : File.join(cache_dir, title, "#{link}.html")
    end

    def generate_cache(milestone, worksheet, link = nil)
      FileUtils.mkdir(cache_dir) unless File.exists?(cache_dir)
      FileUtils.mkdir(File.join(cache_dir, milestone)) if !File.exists?(File.join(cache_dir, milestone)) && !link.nil?
      should_send_to_watchbot = !File.exists?(cache_path(worksheet))
      save_cache_file(milestone, worksheet, link)
      worksheet.send_to_watchbot if should_send_to_watchbot 
    end

    def bridge_cache_key(entry)
      hash = Digest::SHA1.hexdigest(entry.except(:source).to_s)
      entry[:link] + ':' + hash
    end

    protected

    def save_cache_file(milestone, worksheet, link = nil)
      embedly = Bridge::Embedly.new BRIDGE_CONFIG['embedly_key']
      av = ActionView::Base.new(Rails.root.join('app', 'views'))
      av.assign(translations: embedly.parse_entries(worksheet.get_entries(link)), milestone: milestone)
      ActionView::Base.send :include, MediasHelper
      f = File.new(cache_path(worksheet, link), 'w+')
      f.puts(av.render(template: 'medias/embed.html.erb'))
      f.close
    end
  end
end
