module Bridge
  module GoogleAuthentication

    def authenticate
      return @session unless @session.nil?
      begin
        access_token = Rails.cache.fetch('!google_access_token') do
          generate_google_access_token
        end
        @session = GoogleDrive.login_with_oauth(access_token)
        yield if block_given?
      rescue Google::APIClient::AuthorizationError
        access_token = generate_google_access_token
        Rails.cache.write('!google_access_token', access_token)
        @session = GoogleDrive.login_with_oauth(access_token)
        yield if block_given?
      end
    end

    private

    def generate_google_access_token
      require 'google/api_client'
      require 'google/api_client/client_secrets'
      require 'google/api_client/auth/installed_app'
      
      client = Google::APIClient.new(
        :application_name => 'Bridgembed',
        :application_version => '1.0.0'
      )
      
      key = Google::APIClient::KeyUtils.load_from_pkcs12(@config['google_pkcs12_path'], @config['google_pkcs12_secret'])
      client.authorization = Signet::OAuth2::Client.new(
          :token_credential_uri => 'https://accounts.google.com/o/oauth2/token',
          :audience => 'https://accounts.google.com/o/oauth2/token',
          :scope => ['https://www.googleapis.com/auth/drive', 'https://spreadsheets.google.com/feeds/'],
          :issuer => @config['google_issuer'],
          :signing_key => key)
      client.authorization.fetch_access_token!
      client.authorization.access_token
    end
  end
end
