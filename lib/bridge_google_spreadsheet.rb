require 'google_drive'

module Bridge
  class GoogleSpreadsheet
    def initialize(email, password, id, sheet)
      authenticate(email, password)
      get_spreadsheet(id)
      get_worksheet(sheet)
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
          urls << worksheet[row, 2]
        end
        @urls = urls
      end
      @urls
    end

    def updated_at
      get_worksheet.updated.to_i
    end
  
  end
end
