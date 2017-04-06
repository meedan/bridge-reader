#!/usr/bin/env ruby
require File.dirname(__FILE__) + '/../config/environment'
require 'bridge_google_spreadsheet'
require 'bridge_pender'

f = File.open('/tmp/dolly.csv', 'w+')
f.puts 'Milestone,Date,Latitude,Longitude'
%w(1696 1785 1839 1920 2016 2115 2137 2217 2276).each do |nid|
  worksheet = Bridge::GoogleSpreadsheet.new(BRIDGE_CONFIG['google_spreadsheet_id'], nid)
  pender = Bridge::Pender.new BRIDGE_CONFIG['pender_key']
  entries = pender.parse_entries(worksheet.get_entries)
  entries.each do |entry|
    if entry[:oembed]['provider_name'] == 'Twitter'
      lat, lon, date = ''
      unless entry[:oembed]['coordinates'].blank?
        lat = entry[:oembed]['coordinates'][0]
        lon = entry[:oembed]['coordinates'][1]
      end
      date = entry[:oembed]['created_at'].strftime('%Y/%m/%d') unless entry[:oembed]['created_at'].blank?
      f.puts [nid, date, lat, lon].join(',')
    end
  end
end
f.close
