require 'bridge_google_spreadsheet'
require 'bridge_embedly'
require 'bridge_cache'

namespace :bridgembed do
  task rebuild_milestone_cache: :environment do
    include Bridge::Cache

    MAX = 180
    WAIT = 900

    email, pw, sid = BRIDGE_CONFIG['google_email'], BRIDGE_CONFIG['google_password'], BRIDGE_CONFIG['google_spreadsheet_id']

    spreadsheet = Bridge::GoogleSpreadsheet.new(email, pw, sid)
    worksheets = spreadsheet.get_worksheets
    count = 0

    worksheets.each do |w|
      milestone = w.title
      worksheet = Bridge::GoogleSpreadsheet.new(email, pw, sid, milestone)

      puts "[#{Time.now}] Parsing milestone #{milestone}..."
      
      if (w.rows.count - 1 + count) > MAX
        puts "[#{Time.now}] Limit reached, waiting for #{WAIT} seconds before proceeding"
        sleep WAIT
        count = 0
      end

      count += (w.rows.count - 1)
      clear_cache(milestone)
      generate_cache(milestone, worksheet)
      puts "[#{Time.now}] Generated cache file"
    end
  end
end
