module Bridge
  class CcDeville
    def initialize(host, token, httpauth = nil)
      @host = host
      @token = token
      @httpauth = httpauth
    end

    def clear_cache(url)
      response = make_request('delete', 'purge', URI.encode(url))
      response.code.to_i
    end

    def get_status(url)
      response = make_request('get', 'status', URI.encode(url))
      JSON.parse(response.body)
    end

    private

    def make_request(verb, endpoint, url)
      uri = URI.join(@host, endpoint)
      klass = "Net::HTTP::#{verb.camelize}".constantize
      request = klass.new(uri.path + '?url=' + url)
      # unless @httpauth.blank?
      #   username, password = @httpauth.split(':')
      #   request.basic_auth username, password
      # end
      request.add_field('x-cc-deville-token', @token)
      http = Net::HTTP.new(uri.hostname, uri.port)
      http.use_ssl = uri.scheme == 'https'
      http.request(request)
    end
  end
end
