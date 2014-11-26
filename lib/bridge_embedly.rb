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
      @oembeds ||= connect_to_api.oembed(urls: urls)
    end
  end
end
