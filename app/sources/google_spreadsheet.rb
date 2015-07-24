require 'google_drive'
require 'bridge_cache'
require 'bridge_watchbot'

module Sources
  class GoogleSpreadsheet < Base
    include Bridge::Cache

    # First, the methods overwritten from Source::Base

    def initialize(project, config = {})
      @project = project
      @config = config
      authenticate
      super
    end

    def to_s
      get_title
    end

    def get_item(worksheet, hash)
      get_worksheet(worksheet)
      link = get_entries(hash)
      link.blank? ? nil : link.first
    end

    def get_collection(worksheet, hash = nil, force = false)
      get_worksheet(worksheet, force)
      get_entries(nil, force)
    end

    def get_project(worksheet = nil, hash = nil)
      @collections ||= get_worksheets.map(&:title)
    end

    def notify_availability(entry, available)
      if available
        url = entry[:link] + '#' + entry[:source].get_title
        Bridge::Watchbot.new(@config['watchbot']).send(url)
      end

      index = entry[:index]
      worksheet = get_worksheet
      value = available ? 'No' : 'Yes'
      unless worksheet[index, 9].to_s == value.to_s
        worksheet[1, 9] = 'Unavailable?'
        worksheet[index, 9] = value
        Retryable.retryable tries: 5 do
          worksheet.save
        end
      end
    end
    
    def notify_new_item(worksheet, entry)
      if entry.blank?
        url = get_worksheet.spreadsheet.human_url + '#' + worksheet
        Bridge::Watchbot.new(@config['watchbot']).send(url)
      end
    end

    def parse_notification(collection, item, payload = {})
      uri = URI.parse(Rack::Utils.unescape(payload['link']))
      link = uri.to_s.gsub('#' + uri.fragment, '')
      get_worksheet(uri.fragment)
      notify_link_condition(link, payload['condition'])
    end

    # Specific Google Spreadsheets code
    
    def authenticate
      return @session unless @session.nil?
      begin
        access_token = Rails.cache.fetch('!google_access_token') do
          generate_google_access_token
        end
        @session = GoogleDrive.login_with_oauth(access_token)
        get_spreadsheet(@config['google_spreadsheet_id'])
      rescue Google::APIClient::AuthorizationError
        access_token = generate_google_access_token
        Rails.cache.write('!google_access_token', access_token)
        @session = GoogleDrive.login_with_oauth(access_token)
        get_spreadsheet(@config['google_spreadsheet_id'])
      end
    end

    def get_spreadsheet(id = '')
      @spreadsheet ||= @session.spreadsheet_by_key(id)
    end

    def get_title(title = '')
      @title = title
      @title
    end

    def get_url(row)
      get_worksheet[row, 2].gsub(' ', '')
    end

    def get_worksheet(title = '', force = false)
      if @worksheet.blank? || force
        @worksheet = get_spreadsheet.worksheet_by_title(get_title(title))
      end
      @worksheet
    end

    def get_entries(link = nil, force = false)
      if @entries.blank? || force
        worksheet = self.get_worksheet
        @entries = []
        for row in 2..worksheet.num_rows
          Retryable.retryable tries: 5 do
            hash = row_to_hash(row)
            @entries << hash if link.nil? || link == hash[:id]
          end
        end
      end
      @entries
    end

    def get_worksheets
      @worksheets ||= get_spreadsheet.worksheets
    end
    
    protected

    def row_to_hash(row)
      worksheet = get_worksheet
      link = self.get_url(row)
      {
        id: Digest::SHA1.hexdigest(link),
        source_text: worksheet[row, 1],
        source_lang: 'unk',
        link: link,
        timestamp: '',
        translations: [
          {
            translator_name: worksheet[row, 5],
            translator_url: worksheet[row, 6],
            text: worksheet[row, 3],
            lang: 'en',
            timestamp: '',
            comments: [
              {
                commenter_name: worksheet[row, 7],
                commenter_url: worksheet[row, 8],
                comment: worksheet[row, 4],
                timestamp: ''
              }
            ]
          }
        ],
        source: self, 
        index: row 
      }
    end

    def notify_link_condition(link, condition)
      case condition
      when 'check404'
        notify_entry_offline(link)
      when 'check_google_spreadsheet_updated'
        notify_google_spreadsheet_updated
      end
    end

    def notify_entry_offline(link)
      hash = Digest::SHA1.hexdigest(link)
      cache_key = 'embedly:' + hash
      entry = Rails.cache.fetch(cache_key)
      worksheet = self.get_worksheet.title

      unless entry.nil?
        entry[:oembed]['unavailable'] = true
        Rails.cache.write(cache_key, entry)
        entry[:source] = self
        notify_availability(entry, false)
        
        generate_cache(self, self.project, worksheet, '')
        remove_screenshot(self.project, worksheet, '')
        generate_screenshot(self.project, worksheet, '')

        clear_cache(self.project, worksheet, hash)
        remove_screenshot(self.project, worksheet, hash)
      end
    end

    # FIXME: We can improve the performance here
    def notify_google_spreadsheet_updated
      worksheet = self.get_worksheet.title

      entries = self.get_entries
      
      entries.each do |entry|
        hash = entry[:id]
        Rails.cache.delete('embedly:' + hash)
        @entries = [entry]
        generate_cache(self, self.project, worksheet, hash, BRIDGE_CONFIG['bridgembed_host'])
        remove_screenshot(self.project, worksheet, hash)
        # generate_screenshot(self.project, worksheet, hash)
      end

      @entries = entries
      generate_cache(self, self.project, worksheet, '')
      remove_screenshot(self.project, worksheet, '')
      generate_screenshot(self.project, worksheet, '')
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
