require 'google_drive'
require 'bridge_cache'
require 'bridge_watchbot'
require 'bridge_google_authentication'

module Sources
  class GoogleSpreadsheet < Base
    include Bridge::Cache
    include Bridge::GoogleAuthentication

    # First, the methods overwritten from Source::Base

    def initialize(project, config = {})
      @project = project
      @config = config
      authenticate do
        get_spreadsheet(@config['google_spreadsheet_id'])
      end
      super
    end

    def to_s
      get_title
    end

    def get_item(worksheet, hash)
      return if get_worksheet(worksheet).blank?
      link = get_entries(hash)
      link.blank? ? nil : link.first
    end

    def get_collection(worksheet, hash = nil, force = false)
      return if get_worksheet(worksheet, force).blank?
      get_entries(nil, force)
    end

    def get_project(worksheet = nil, hash = nil)
      @collections ||= get_worksheets.map(&:title).collect{ |title| { 'name' => title, 'id' => title, 'project' => @project } }
    end

    def notify_availability(entry, available)
      if available
        url = entry[:link] + '#' + entry[:source].get_title
        self.notify_watchbot(url)
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
      if entry.blank? && worksheet.present?
        url = get_worksheet.spreadsheet.human_url + '#' + worksheet
        self.notify_watchbot(url)
      end
    end

    def notify_watchbot(url)
      Bridge::Watchbot.new(@config['watchbot']).send(url)
    end

    def parse_notification(collection, item, payload = {})
      uri = URI.parse(Rack::Utils.unescape(payload['link']))
      link = uri.to_s.gsub('#' + uri.fragment, '')
      get_worksheet(uri.fragment)
      notify_link_condition(link, payload['condition'])
    end

    def get_spreadsheet(id = '')
      @spreadsheet ||= @session.spreadsheet_by_key(id)
    end

    def get_title(title = '')
      @title = title unless title.blank?
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
      @entries.reverse
    end

    def get_worksheets
      @worksheets ||= get_spreadsheet.worksheets
    end
    
    protected

    def row_to_hash(row)
      worksheet = get_worksheet
      link = self.get_url(row)
      comment = worksheet[row, 4]
      {
        id: Digest::SHA1.hexdigest(link),
        source_text: worksheet[row, 1],
        source_lang: 'unk',
        source_author_name: worksheet[row, 11],
        source_author_link: worksheet[row, 12],
        link: link,
        timestamp: worksheet[row, 10],
        translations: [
          {
            translator_name: worksheet[row, 5],
            translator_url: worksheet[row, 6],
            text: worksheet[row, 3],
            lang: 'en',
            timestamp: '',
            comments:
              comment.blank? ?
                [] :
                [
                  {
                    commenter_name: worksheet[row, 7],
                    commenter_url: worksheet[row, 8],
                    comment: comment,
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
        
        self.refresh_cache_milestone

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
      self.refresh_cache_milestone
    end

    def refresh_cache_milestone
      worksheet = self.get_worksheet.title
      generate_cache(self, self.project, worksheet, '')
      remove_screenshot(self.project, worksheet, '')
      # generate_screenshot(self.project, worksheet, '')
    end
  end
end
