require 'google_drive'
require 'bridge_embedly'
require 'bridge_cache'
require 'bridge_watchbot'

module Bridge
  class GoogleSpreadsheet
    include Bridge::Cache

    def initialize(id, sheet = nil)
      @entries = []
      authenticate(id)
      sheet.nil? ? get_worksheets : get_worksheet(sheet)
    end
    
    def authenticate(spreadsheet_id)
      return @session unless @session.nil?
      begin
        access_token = Rails.cache.fetch('!google_access_token') do
          generate_google_access_token
        end
        @session = GoogleDrive.login_with_oauth(access_token)
        get_spreadsheet(spreadsheet_id)
      rescue Google::APIClient::AuthorizationError
        access_token = generate_google_access_token
        Rails.cache.write('!google_access_token', access_token)
        @session = GoogleDrive.login_with_oauth(access_token)
        get_spreadsheet(spreadsheet_id)
      end
    end

    def get_spreadsheet(id = '')
      @spreadsheet ||= @session.spreadsheet_by_key(id)
    end

    def get_title(title = '')
      @title ||= title
    end

    def get_worksheet(title = '')
      @worksheet ||= get_spreadsheet.worksheet_by_title(get_title(title))
    end

    def get_urls
      unless @urls
        worksheet = get_worksheet
        urls = []
        # FIXME: Assuming that the first row is the header
        for row in 2..worksheet.num_rows
          # FIXME: Link column index is hard-coded here
          Retryable.retryable tries: 5 do
            urls << worksheet[row, 2]
          end
        end
        @urls = urls
      end
      @urls
    end

    def get_entries(link = nil, force = false)
      if @entries.empty? || force
        worksheet = get_worksheet
        @entries = []
        for row in 2..worksheet.num_rows
          Retryable.retryable tries: 5 do
            @entries << row_to_hash(row) if link.nil? || link == Digest::SHA1.hexdigest(worksheet[row, 2])
          end
        end
      end
      @entries
    end

    def get_worksheets
      @worksheets ||= get_spreadsheet.worksheets
    end

    def get_link(hash)
      link = Rails.cache.fetch(hash) do
        get_worksheets.each do |worksheet|
          @worksheet = worksheet
          get_entries(hash)
          break unless @entries.empty? 
        end
        @entries.empty? ? nil : { title: @worksheet.title, url: @entries[0][:link] }
      end

      unless link.nil?
        get_worksheet(link[:title])
        get_entries(hash).first
      end
    end

    def notify_availability(index, available)
      #FIXME: Cell position is hard-coded here
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

    def to_s
      get_title
    end

    def url
      get_worksheet.spreadsheet.human_url + '#' + get_title
    end

    def send_to_watchbot
      Bridge::Watchbot.new.send(self.url)
    end

    def notify_link_condition(link, condition)
      case condition
      when 'check404'
        notify_entry_offline(link)
      when 'check_google_spreadsheet_updated'
        notify_google_spreadsheet_updated
      end
    end
    
    protected

    def row_to_hash(row)
      worksheet = get_worksheet
      {
        source_text: worksheet[row, 1],
        link: worksheet[row, 2],
        translation: worksheet[row, 3],
        comment: worksheet[row, 4],
        translator_name: worksheet[row, 5],
        translator_url: worksheet[row, 6],
        commenter: worksheet[row, 7],
        commenter_url: worksheet[row, 8],
        source: self,
        index: row
      }
    end

    def notify_entry_offline(link)
      hash = Digest::SHA1.hexdigest(link)
      entry = self.get_entries(hash).first
      return if entry.nil?
      Rails.cache.write(bridge_cache_key(entry), entry.except(:source).merge({ oembed: { 'unavailable' => true }}))
      notify_availability(entry[:index], false)
      generate_cache(self, 'milestone', self.get_worksheet.title)
      self.get_entries(hash, true)
      generate_cache(self, 'link', hash, BRIDGE_CONFIG['bridgembed_host'])
    end

    def notify_google_spreadsheet_updated
      generate_cache(self, 'milestone', self.get_worksheet.title)

      self.get_entries.each do |entry|
        hash = Digest::SHA1.hexdigest(entry[:link])
        self.get_entries(hash, true)
        generate_cache(self, 'link', hash, BRIDGE_CONFIG['bridgembed_host'])
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
      
      key = Google::APIClient::KeyUtils.load_from_pkcs12(BRIDGE_CONFIG['google_pkcs12_path'], BRIDGE_CONFIG['google_pkcs12_secret'])
      client.authorization = Signet::OAuth2::Client.new(
          :token_credential_uri => 'https://accounts.google.com/o/oauth2/token',
          :audience => 'https://accounts.google.com/o/oauth2/token',
          :scope => ['https://www.googleapis.com/auth/drive', 'https://spreadsheets.google.com/feeds/'],
          :issuer => BRIDGE_CONFIG['google_issuer'],
          :signing_key => key)
      client.authorization.fetch_access_token!
      client.authorization.access_token
    end
  end
end
