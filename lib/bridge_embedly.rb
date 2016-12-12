require 'embedly'
require 'json'
require 'twitter'

module Bridge
  class Embedly

    def initialize(key)
      connect_to_api(key)
    end

    def connect_to_api(key = '')
      @api ||= ::Embedly::API.new(key: key, user_agent: 'Mozilla/5.0 (compatible; Bridge/1.0; bridge@meedanlabs.com)')
    end

    def call_oembed(link)
      oembed = {}
      Retryable.retryable tries: 5, sleep: 3 do
        oembed = connect_to_api.oembed(url: link).first
      end
      raise oembed.error_message if oembed.type === 'error'
      oembed[:link] = link
      oembed
    end

    def parse_entry(entry)
      if entry[:link].blank?
        parse_non_link_entry(entry)
      else
        parse_link_entry(entry)
      end
    end

    def parse_link_entry(entry)
      Rails.cache.fetch('embedly:' + entry[:id]) do
        begin
          oembed = call_oembed(entry[:link])
          entry[:provider] = provider = oembed.provider_name.to_s.underscore
          entry[:oembed] = self.alter_oembed(oembed, provider)
        rescue
          entry[:oembed] = { 'unavailable' => true }
        end
        entry[:oembed]['unavailable'] ? notify_unavailable(entry) : notify_available(entry)
        entry.except(:source)
      end
    end

    def parse_non_link_entry(entry)
      entry[:oembed] = { 'unavailable' => false }
      entry.except(:source)
    end

    def parse_collection(entries)
      parsed = []
      entries.each_with_index do |entry, i|
        entry = parse_item(entry)
        parsed << entry unless entry[:oembed]['unavailable']
      end
      parsed
    end

    def parse_item(entry)
      parse_entry(entry)
    end

    def parse_project(collections)
      collections
    end

    def notify_available(entry)
      entry[:source].notify_availability(entry, true) unless entry[:source].nil?
    end

    def notify_unavailable(entry)
      entry[:source].notify_availability(entry, false) unless entry[:source].nil?
    end

    def alter_oembed(oembed, provider)
      function = "alter_#{provider}_oembed"
      oembed['unavailable'] = true if oembed.respond_to?(:error_code) && oembed.error_code === 404
      (oembed = self.send(function, oembed)) if self.respond_to?(function)
      oembed
    end

    # Methods to alter responses for some providers

    def alter_twitter_oembed(oembed)
      id = oembed[:link].match(/status\/([0-9]+)/)
      oembed[:author_full_name] = oembed[:title].gsub(/ on Twitter$/, '')
      unless id.nil?
        Retryable.retryable tries: 5, sleep: 3 do
          begin
            oembed = add_twitter_info(oembed)
          rescue Twitter::Error::NotFound, Twitter::Error::Forbidden
            oembed['unavailable'] = true
          rescue Twitter::Error::TooManyRequests => error
            sleep error.rate_limit.reset_in.to_i
          end
        end
      end
      oembed
    end

    def add_twitter_info(oembed)
      id = oembed[:link].match(/status\/([0-9]+)/)
      oembed['twitter_id'] = id[1]
      client = Twitter::REST::Client.new do |config|
        config.consumer_key        = BRIDGE_CONFIG['twitter_consumer_key']
        config.consumer_secret     = BRIDGE_CONFIG['twitter_consumer_secret']
        config.access_token        = BRIDGE_CONFIG['twitter_access_token']
        config.access_token_secret = BRIDGE_CONFIG['twitter_access_token_secret']
      end
      tweet = client.status(id[1])
      oembed['coordinates'] = [tweet.geo.latitude, tweet.geo.longitude] if tweet.geo?
      oembed['created_at'] = tweet.created_at
      oembed
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
