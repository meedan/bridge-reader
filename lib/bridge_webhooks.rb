module Bridge
  module Webhooks

    def parse_notification(channel, translation_id, payload = {})
      if !payload['project'].blank?
        self.handle_project(payload)
      elsif payload['condition'] == 'created' || payload['condition'] == 'updated'
        self.update_cache_for_saved_translation(channel, payload['translation'])
      elsif payload['condition'] == 'destroyed'
        self.update_cache_for_removed_translation(channel, translation_id)
      end
      refresh_cache(channel) unless channel.blank?
    end

    def handle_project(payload)
      if payload['condition'] == 'created'
        klass = 'Sources::' + @project.underscore.camelize
        config = klass.constantize.base_config(payload)
        slug = payload['project']['slug']
        create_config_file_for_project(slug, config[:info])
        BRIDGE_PROJECTS[slug] = config[:info]
      elsif payload['condition'] == 'updated'
        generate_cache(self, self.project, '', '')
      end
    end

    def refresh_cache(channel)
      generate_cache(self, self.project, channel, '')
      remove_screenshot(self.project, channel, '')
      generate_cache(self, self.project, '', '')
      remove_screenshot(self.project, '', '')
    end

    def update_cache_for_saved_translation(channel, translation)
      Rails.cache.delete('pender:' + translation['id'].to_s)
      @entries = [translation]
      generate_cache(self, self.project, channel, translation['id'].to_s)
      remove_screenshot(self.project, channel, translation['id'].to_s)
      @entries = nil
    end

    def update_cache_for_removed_translation(channel, translation_id)
      clear_cache(self.project, channel, translation_id.to_s)
      remove_screenshot(self.project, channel, translation_id.to_s)
    end

    def create_config_file_for_project(slug, info)
      dir = File.join(Rails.root, 'config', 'projects', Rails.env)
      path = File.join(dir, slug + '.yml')
      file = File.open(path, 'w+')
      info.each do |key, value|
        file.puts("#{key}: '#{value}'")
      end
      file.close
    end

  end
end
