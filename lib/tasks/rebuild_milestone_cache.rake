require 'bridge_google_spreadsheet'
require 'bridge_embedly'
require 'bridge_cache'

namespace :bridgembed do
  task rebuild_milestone_cache: :environment do
    include Bridge::Cache

    MAX = 180
    WAIT = ENV['WAIT_INTERVAL'] || 900

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
        sleep WAIT.to_i
        count = 0
      end

      count += (w.rows.count - 1)
      
      generate_cache(worksheet, 'milestone', milestone)

      entries = worksheet.get_entries

      entries.each do |e|
        id = Digest::SHA1.hexdigest(e[:link])
        worksheet.get_entries(id, true)
        generate_cache(worksheet, 'link', id, BRIDGE_CONFIG['bridgembed_host'])
        generate_screenshot('link', id)
      end

      puts "[#{Time.now}] Generated cache file"
    end
  end

  task rebuild_all_cache: :environment do
    Rake::Task['bridgembed:clear_all_cache'].execute
    Rake::Task['bridgembed:rebuild_milestone_cache'].execute
  end
end
