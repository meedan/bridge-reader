require 'google_drive'
require 'bridge_cache'
require 'bridge_watchbot'

module Bridge
  class GoogleSpreadsheet
    include Bridge::Cache

    def initialize(email, password, id, sheet = nil)
      authenticate(email, password)
      get_spreadsheet(id)
      sheet.nil? ? get_worksheets : get_worksheet(sheet)
    end
    
    def authenticate(email = '', password = '')
      @session ||= GoogleDrive::Session.login(email, password)
    end

    def get_spreadsheet(id = '')
      @spreadsheet ||= authenticate.spreadsheet_by_key(id)
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

    def get_entries
      unless @entries
        worksheet = get_worksheet
        @entries = []
        for row in 2..worksheet.num_rows
          Retryable.retryable tries: 5 do
            @entries << {
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
        end
      end
      @entries
    end

    def version
      # get_worksheet.updated.to_i
      get_worksheet[2, 10].to_i
    end

    def update_version
      get_worksheet[2, 10] = version + 1
    end
  
    def get_worksheets
      @worksheets ||= get_spreadsheet.worksheets
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

    def notify_link_condition(link, condition)
      entry = self.get_entries.select{ |e| e[:link] == link }.first
      return if entry.nil?
 
      if condition == 'check404'
        Rails.cache.write(bridge_cache_key(entry), entry.merge({ oembed: { 'unavailable' => true }}))
        update_version
        notify_availability(entry[:index], false)
      end
    end

    def url
      get_worksheet.spreadsheet.human_url + '#' + get_title
    end

    def send_to_watchbot
      Bridge::Watchbot.new.send(self.url)
    end
  end
end
