require 'json'
require 'twitter'

module Bridge
  class Pender

    def initialize(key)
      connect_to_api(key)
    end

    def connect_to_api(_key = '')
      @api ||= PenderClient::Request
    end

    def call_oembed(link)
      oembed = {}
      response = nil
      Retryable.retryable tries: 5, sleep: 3 do
        response = connect_to_api.get_medias(BRIDGE_CONFIG['pender_base_url'], { url: link }, BRIDGE_CONFIG['pender_token'])
      end
      raise response['data']['message'] if response['type'] === 'error'
      # raise oembed['data']['error']['message'] if oembed['data'].has_key?('error')
      oembed = response['data'].dup
      oembed[:link] = link
      oembed
    end

    def parse_entry(entry)
      return if entry.blank?
      if entry[:link].blank?
        parse_non_link_entry(entry)
      else
        parse_link_entry(entry)
      end
    end

    def parse_link_entry(entry)
      Rails.cache.fetch('pender:' + entry[:id]) do
        begin
          oembed = call_oembed(entry[:link])
          entry[:provider] = provider = oembed['provider'].to_s.underscore
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
      return if entries.blank?
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
      oembed['unavailable'] = true if oembed.has_key?('error')
      (oembed = self.send(function, oembed)) if self.respond_to?(function)
      oembed
    end

    # Methods to alter responses for some providers

    def alter_twitter_oembed(oembed)
      id = oembed[:link].match(/status\/([0-9]+)/)
      oembed[:author_full_name] = oembed['username']
      unless id.nil?
        Retryable.retryable tries: 5, sleep: 3 do
          oembed = add_twitter_info(oembed)
        end
      end
      oembed
    end

    def add_twitter_info(oembed)
      id = oembed[:link].match(/status\/([0-9]+)/)
      oembed['twitter_id'] = id[1]
      oembed['coordinates'] = [oembed['geo']['coordinates'][0], oembed['geo']['coordinates'][1]] if oembed['geo']
      oembed['created_at'] = Time.parse(oembed['published_at'])
      oembed['unavailable'] = true if oembed['protected']
      oembed
    end
  end
end
