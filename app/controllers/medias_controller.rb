require 'bridge_google_spreadsheet'
require 'bridge_embedly'
class MediasController < ApplicationController
  after_action :allow_iframe, only: :embed

  def embed
    milestone = params[:milestone]
    worksheet = Bridge::GoogleSpreadsheet.new(BRIDGE_CONFIG['google_email'],
                                              BRIDGE_CONFIG['google_password'],
                                              BRIDGE_CONFIG['google_spreadsheet_id'],
                                              milestone)

    cache = cache_path(worksheet)
    if BRIDGE_CONFIG['cache_embeds'] && File.exists?(cache)
      puts "Using cache at #{cache}"
    else
      clear_cache(milestone)
      generate_cache(worksheet, cache)
    end

    render file: cache
  end

  private

  def clear_cache(milestone)
    FileUtils.rm Dir.glob(File.join(Rails.root, 'public', "#{milestone}_*"))
    puts "Cache cleared"
  end

  def cache_path(worksheet)
    File.join(Rails.root, 'public', "#{worksheet.get_title}_#{worksheet.updated_at}.html")
  end

  def generate_cache(worksheet, cache)
    @embedly = Bridge::Embedly.new BRIDGE_CONFIG['embedly_key']
    av = ActionView::Base.new(Rails.root.join('app', 'views'))
    av.assign(translations: @embedly.parse_entries(worksheet.get_entries))
    f = File.new(cache, 'w+')
    f.puts(av.render(template: 'medias/checkdesk.erb.html'))
    f.close
    puts "Cache generated at #{cache}"
  end

  def allow_iframe
    response.headers.except! 'X-Frame-Options'
  end
end
