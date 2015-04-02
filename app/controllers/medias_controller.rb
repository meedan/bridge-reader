require 'bridge_google_spreadsheet'
require 'bridge_embedly'
require 'bridge_cache'

class MediasController < ApplicationController
  include Bridge::Cache

  after_action :allow_iframe, only: :embed

  def all
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
    time = Benchmark.ms{
      @worksheet = Bridge::GoogleSpreadsheet.new(BRIDGE_CONFIG['google_email'],
                                                 BRIDGE_CONFIG['google_password'],
                                                 BRIDGE_CONFIG['google_spreadsheet_id'],
                                                 @milestone)
    }
    Rails.logger.info "  Fetched information from Google Spreadsheet (#{time.round(1)}ms)"

    @cachepath = cache_path(@worksheet)
    if BRIDGE_CONFIG['cache_embeds'] && File.exists?(@cachepath)
      @cache = true
    else
      clear_cache(@milestone)
      generate_cache(@milestone, @worksheet)
      @cache = false
    end

    render file: @cachepath
  end

  def allow_iframe
    response.headers.except! 'X-Frame-Options'
  end
end
