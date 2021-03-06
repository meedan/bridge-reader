module Bridge
  class Watchbot
   
    def initialize(config = {})
      @config = config
      @url = @config['url']
      @uri = URI.parse(@url) unless @url.blank?
    end

    def send(link)
      response = nil
      if @url.blank?
        Rails.logger.info 'Not sending to WatchBot because its URL is not set on the configuration file'
      else
        response = self.request(link)
        Rails.logger.info 'Sent to the WatchBot'
      end
      response
    end

    protected

    def request(link)
      request = Net::HTTP::Post.new(@uri.path)
      request.set_form_data({ url: link })
      request['Authorization'] = 'Token token=' + @config['token'].to_s
      http = Net::HTTP.new(@uri.hostname, @uri.port)
      http.use_ssl = @uri.scheme == 'https'
      http.request(request)
    end
  end
end
