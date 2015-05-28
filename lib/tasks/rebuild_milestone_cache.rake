require 'bridge_google_spreadsheet'
require 'bridge_embedly'
require 'bridge_cache'

namespace :bridgembed do
  task rebuild_milestone_cache: :environment do
    include Bridge::Cache

    MAX = 180
    WAIT = ENV['WAIT_INTERVAL'] || 900

    sid = BRIDGE_CONFIG['google_spreadsheet_id']

    spreadsheet = Bridge::GoogleSpreadsheet.new(sid)
    worksheets = spreadsheet.get_worksheets.map(&:title)
    count = 0

    worksheets.each do |milestone|
      puts "[#{Time.now}] Parsing milestone #{milestone}..."
      
      worksheet = Bridge::GoogleSpreadsheet.new(sid, milestone)
      
      if (worksheet.rows.count - 1 + count) > MAX
        puts "[#{Time.now}] Limit reached, waiting for #{WAIT} seconds before proceeding"
        sleep WAIT.to_i
        count = 0
      end
      
      worksheet = Bridge::GoogleSpreadsheet.new(sid, milestone)

      count += (worksheet.rows.count - 1)
      
      generate_cache(worksheet, 'milestone', milestone)

      entries = worksheet.get_entries

      entries.each do |e|
        id = Digest::SHA1.hexdigest(e[:link])
        worksheet.get_entries(id, true)
        generate_cache(worksheet, 'link', id, BRIDGE_CONFIG['bridgembed_host'])
        begin
          generate_screenshot('link', id)
        rescue
          puts "Could not generate screenshot for link #{e[:link]} (hash = #{id})"
        end
      end

      puts "[#{Time.now}] Generated cache file"
    end
  end

  task rebuild_all_cache: :environment do
    Rake::Task['bridgembed:clear_all_cache'].execute
    Rake::Task['bridgembed:rebuild_milestone_cache'].execute
  end
end
