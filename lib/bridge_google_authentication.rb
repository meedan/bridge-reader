module Bridge
  module GoogleAuthentication

    def authenticate
      return @session unless @session.nil?
      begin
        @session = GoogleDrive::Session.from_service_account_key(File.join(Rails.root, @config['google_credentials_path']))
        yield if block_given?
      rescue Signet::AuthorizationError => e
        Rails.logger.info "[Google Drive] Cannot authenticate on spreadsheet `#{@config['google_spreadsheet_id']}` with the credentials: #{e.class} - #{e.message}"
      end
    end
  end
end
