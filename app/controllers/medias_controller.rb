require 'bridge_google_spreadsheet'
require 'bridge_embedly'
class MediasController < ApplicationController
  after_action :allow_iframe, only: :embed

  def index
    @spreadsheet = Bridge::GoogleSpreadsheet.new(BRIDGE_CONFIG['google_email'],
                                                 BRIDGE_CONFIG['google_password'],
                                                 BRIDGE_CONFIG['google_spreadsheet_id'])
    @worksheets = @spreadsheet.get_worksheets
    @host = request.host
  end

  def embed
    @milestone = params[:milestone]

    respond_to do |format|
      format.html { render_embed_as_html }
      format.js   { render_embed_as_js   }
    end
  end

  private

  def render_embed_as_js
    @url = request.original_url.gsub(/\.js$/, '')
  end

  def render_embed_as_html
    @worksheet = Bridge::GoogleSpreadsheet.new(BRIDGE_CONFIG['google_email'],
                                               BRIDGE_CONFIG['google_password'],
                                               BRIDGE_CONFIG['google_spreadsheet_id'],
                                               @milestone)

    @cachepath = cache_path
    if BRIDGE_CONFIG['cache_embeds'] && File.exists?(@cachepath)
      @cache = true
    else
      clear_cache
      generate_cache
      @cache = false
    end

    render file: @cachepath
  end

  def clear_cache
    FileUtils.rm Dir.glob(File.join(Rails.root, 'public', "#{@milestone}_*"))
  end

  def cache_path
    File.join(Rails.root, 'public', "#{@worksheet.get_title}_#{@worksheet.updated_at}.html")
  end

  def generate_cache
    @embedly = Bridge::Embedly.new BRIDGE_CONFIG['embedly_key']
    av = ActionView::Base.new(Rails.root.join('app', 'views'))
    av.assign(translations: @embedly.parse_entries(@worksheet.get_entries), milestone: @milestone)
    ActionView::Base.send :include, MediasHelper
    f = File.new(@cachepath, 'w+')
    f.puts(av.render(template: 'medias/embed.html.erb'))
    f.close
  end

  def allow_iframe
    response.headers.except! 'X-Frame-Options'
  end
end
