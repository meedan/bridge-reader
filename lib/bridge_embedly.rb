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
        function = "alter_#{oembed.provider_name.underscore}_oembed"
        (oembed = self.send(function, oembed)) if self.respond_to?(function)
        oembed
      end
    end

    def parse_entries(entries = [])
      unless @entries
        @entries = []
        entries.each do |entry|
          oembed = connect_to_api.oembed(url: entry[:link]).first
          function = "alter_#{oembed.provider_name.underscore}_oembed"
          (oembed = self.send(function, oembed)) if self.respond_to?(function)
          entry[:oembed] = oembed
          @entries << entry
        end
      end
      @entries
    end

    # Methods to alter responses for some providers

    def alter_twitter_oembed(oembed)
      require 'twitter'
      id = oembed.url.match(/status\/([0-9]+)/)
      unless id.nil?
        begin
          client = connect_to_twitter
          tweet = client.status(id[1])
          oembed['coordinates'] = [tweet.geo.latitude, tweet.geo.longitude] if tweet.geo?
          oembed['created_at'] = tweet.created_at
        rescue
          # Do nothing
        end
      end
      oembed
    end

    def connect_to_twitter
      Twitter::REST::Client.new do |config|
        config.consumer_key        = BRIDGE_CONFIG['twitter_consumer_key']
        config.consumer_secret     = BRIDGE_CONFIG['twitter_consumer_secret']
        config.access_token        = BRIDGE_CONFIG['twitter_access_token']
        config.access_token_secret = BRIDGE_CONFIG['twitter_token_secret']
      end
    end
  end
end
