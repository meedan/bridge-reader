module Bridge
  module Cache
    def cache_dir
      File.join(Rails.root, 'public', 'cache')
    end

    def clear_cache(milestone)
      FileUtils.rm Dir.glob(File.join(cache_dir, "#{milestone}_*"))
    end

    def cache_path(worksheet)
      File.join(cache_dir, "#{worksheet.get_title}_#{worksheet.version}.html")
    end

    def generate_cache(milestone, worksheet)
      @embedly = Bridge::Embedly.new BRIDGE_CONFIG['embedly_key']
      av = ActionView::Base.new(Rails.root.join('app', 'views'))
      av.assign(translations: @embedly.parse_entries(worksheet.get_entries), milestone: milestone)
      ActionView::Base.send :include, MediasHelper
      FileUtils.mkdir(cache_dir) unless File.exists?(cache_dir)
      f = File.new(cache_path(worksheet), 'w+')
      f.puts(av.render(template: 'medias/embed.html.erb'))
      f.close
    end
  end
end
