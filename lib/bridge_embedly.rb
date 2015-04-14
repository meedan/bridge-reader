require 'embedly'
require 'json'
require 'bridge_cache'
require 'bridge_watchbot'

module Bridge
  class Embedly
    include Bridge::Cache

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

    def call_oembed(link)
      oembed = {}
      Retryable.retryable tries: 5, sleep: 3 do
        oembed = connect_to_api.oembed(url: link).first
      end
      oembed[:link] = link
      oembed
    end

    def parse_entry(entry)
      Rails.cache.fetch(bridge_cache_key(entry)) do
        link = entry[:link]
        Rails.cache.delete_matched(/^#{link}:/)
        oembed = call_oembed(link)
        entry[:provider] = provider = oembed.provider_name.to_s.underscore
        entry[:oembed] = self.alter_oembed(oembed, provider)
        entry[:oembed]['unavailable'] ? notify_unavailable(entry) : notify_available(entry)
        entry
      end
    end

    def parse_entries(entries = [])
      unless @entries
        @entries = []
        entries.each do |entry|
          entry = parse_entry(entry)
          @entries << entry unless entry[:oembed]['unavailable']
        end
      end
      @entries
    end

    def send_to_watchbot(entry)
      Bridge::Watchbot.new.send(entry[:link] + '#' + entry[:source].to_s)
    end

    def notify_available(entry)
      send_to_watchbot(entry)
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
        Retryable.retryable tries: 5, sleep: 3 do
          begin
            client = connect_to_twitter
            tweet = client.status(id[1])
            oembed['coordinates'] = [tweet.geo.latitude, tweet.geo.longitude] if tweet.geo?
            oembed['created_at'] = tweet.created_at
          rescue Twitter::Error::NotFound, Twitter::Error::Forbidden
            oembed['unavailable'] = true
          end
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
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = uri.scheme == 'https'
      result = http.get(uri.path)
      oembed['unavailable'] = (result.code.to_i === 404)
      oembed
    end
  end
end
