require 'bridge_cache'

module Sources
  class BridgeApi < Base
    include Bridge::Cache

    # First, the methods overwritten from Source::Base

    def initialize(project, config = {})
      @project = project
      @config = config
      # authenticate
      super
    end

    def to_s
      @project
    end

    def get_item(channel, translation_id)
      translation = self.make_request("translations/#{translation_id.to_i}")
      translation_to_hash(translation) unless translation.nil?
    end

    def get_collection(channel, translation_id = nil, force = false)
      if @translations.nil? || force
        @translations = self.make_request('translations', { channel_uuid: channel })
      end
      @translations.to_a.collect{ |t| translation_to_hash(t) }
    end

    def get_project(channel = nil, translation_id = nil)
      self.make_request("projects/#{@project}/channels").to_a.collect{ |c| c['id'] }
    end

    def parse_notification(channel, translation_id, payload = {})
      if payload['condition'] == 'created' || payload['condition'] == 'updated'
        self.update_cache_for_saved_translation(channel, payload['translation'])
      elsif payload['condition'] == 'destroyed'
        self.update_cache_for_removed_translation(channel, translation_id)
      end

      generate_cache(self, self.project, channel, '', BRIDGE_CONFIG['bridgembed_host'])
      remove_screenshot(self.project, channel, '')
    end

    def update_cache_for_saved_translation(channel, translation)
      Rails.cache.delete('embedly:' + translation['id'].to_s)
      @entries = [translation]
      generate_cache(self, self.project, channel, translation['id'].to_s, BRIDGE_CONFIG['bridgembed_host'])
      remove_screenshot(self.project, channel, translation['id'].to_s)
      @entries = nil
    end

    def update_cache_for_removed_translation(channel, translation_id)
      clear_cache(self.project, channel, translation_id.to_s) 
      remove_screenshot(self.project, channel, translation_id.to_s)
    end

    def translation_to_hash(translation)
      hash = {
        id: translation['id'].to_s,
        source_text: translation['source']['text'],
        source_lang: translation['source']['lang'],
        link: translation['source']['link'],
        timestamp: translation['source']['published'],
        translations: [
          {
            translator_name: translation['author']['name'],
            translator_url: translation['author']['link'],
            text: translation['text'],
            lang: translation['lang'],
            timestamp: translation['published'],
            comments: self.comments_from_translation(translation)
          }
        ],
        source: self,
        index: translation['id'].to_s
      }
      hash
    end

    def comments_from_translation(translation)
      comments = []
      translation['comments'].each do |comment|
        comments << {
          commenter_name: comment['author']['name'],
          commenter_url: comment['author']['link'],
          comment: comment['text'],
          timestamp: comment['published']
        }
      end
      comments
    end

    protected

    def format_params(params = {})
      query = []
      params.each do |key, value|
        query << "#{key}=#{value}"
      end
      query.join('&')
    end

    def make_request(endpoint, params = {})
      uri = URI.join(@config['bridge_api_host'], 'api/', endpoint)
      request = Net::HTTP::Get.new(uri.path + '?' + format_params(params))
      request['Authorization'] = 'Token token=' + @config['bridge_api_token'].to_s
      http = Net::HTTP.new(uri.hostname, uri.port)
      http.use_ssl = uri.scheme == 'https'
      response = http.request(request)
      parse_response(response)
    end

    def parse_response(response)
      response.code.to_i === 200 ? JSON.parse(response.body)['data'] : nil
    end
  end
end