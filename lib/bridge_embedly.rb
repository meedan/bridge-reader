require 'embedly'
require 'json'

module Bridge
  class Embedly
    def initialize(key)
      connect_to_api(key)
    end

    def connect_to_api(key = '')
      @api ||= ::Embedly::API.new(key: key, user_agent: 'Mozilla/5.0 (compatible; Bridge/1.0; bridge@meedanlabs.com)')
    end

    def objects_from_urls(urls = [])
      @oembeds ||= connect_to_api.oembed(urls: urls).collect do |oembed|
        oembed[:link] = oembed[:url]
        function = "alter_#{oembed.provider_name.underscore}_oembed"
        (oembed = self.send(function, oembed)) if self.respond_to?(function)
        oembed
      end
    end

    def parse_entries(entries = [])
      unless @entries
        @entries = []
        entries.each do |entry|
          link = entry[:link]
          oembed = connect_to_api.oembed(url: link).first
          oembed[:link] = link
          entry[:provider] = provider = oembed.provider_name.to_s.underscore
          entry[:oembed] = self.alter_oembed(oembed, provider)
          entry[:oembed]['unavailable'] ? notify_unavailable(entry) : notify_available(entry)
        end
      end
      @entries
    end

    def notify_available(entry)
      @entries << entry
      entry[:source].notify_availability(entry[:index], true) unless entry[:source].nil?
    end

    def notify_unavailable(entry)
      entry[:source].notify_availability(entry[:index], false) unless entry[:source].nil?
    end

    def alter_oembed(oembed, provider)
      function = "alter_#{provider}_oembed"
      oembed['unavailable'] = true if oembed.respond_to?(:error_code) && oembed.error_code === 404
      (oembed = self.send(function, oembed)) if self.respond_to?(function)
      oembed
    end

    # Methods to alter responses for some providers

    def alter_twitter_oembed(oembed)
      require 'twitter'
      id = oembed[:link].match(/status\/([0-9]+)/)
      unless id.nil?
        begin
          client = connect_to_twitter
          tweet = client.status(id[1])
          oembed['coordinates'] = [tweet.geo.latitude, tweet.geo.longitude] if tweet.geo?
          oembed['created_at'] = tweet.created_at
        rescue
          oembed['unavailable'] = true
        end
      end
      oembed
    end

    def connect_to_twitter
      Twitter::REST::Client.new do |config|
        config.consumer_key        = BRIDGE_CONFIG['twitter_consumer_key']
        config.consumer_secret     = BRIDGE_CONFIG['twitter_consumer_secret']
        config.access_token        = BRIDGE_CONFIG['twitter_access_token']
        config.access_token_secret = BRIDGE_CONFIG['twitter_access_token_secret']
      end
    end

    def alter_instagram_oembed(oembed)
      uri = URI.parse(oembed[:link])
      result = Net::HTTP.start(uri.host, uri.port) { |http| http.get(uri.path) }
      oembed['unavailable'] = (result.code.to_i === 404)
      oembed
    end
  end
end
