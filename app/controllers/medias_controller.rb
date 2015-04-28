require 'bridge_google_spreadsheet'
require 'bridge_embedly'
require 'bridge_cache'
require 'bridge_error_codes'

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
    @link = params[:link]

    respond_to do |format|
      format.html { render_embed_as_html }
      format.js   { render_embed_as_js   }
    end
  end

  def notify
    begin
      payload = request.raw_post
      if verify_signature(payload)
        parse_notification(payload)
        render_success
      else
        render_error 'Signature could not be verified', 'INVALID_SIGNATURE'
      end
    rescue Exception => e
      render_error e.message, 'EXCEPTION'
    end
  end

  private

  def render_embed_as_js
    @caller = request.original_url
    @url = @caller.gsub(/\.js$/, '')
  end

  def render_embed_as_html
    @cachepath = cache_path(@milestone, @link)
    if BRIDGE_CONFIG['cache_embeds'] && File.exists?(@cachepath)
      @cache = true
    else
      time = Benchmark.ms{
        @worksheet = Bridge::GoogleSpreadsheet.new(BRIDGE_CONFIG['google_email'],
                                                   BRIDGE_CONFIG['google_password'],
                                                   BRIDGE_CONFIG['google_spreadsheet_id'],
                                                   @milestone)
      }
      Rails.logger.info "  Fetched information from Google Spreadsheet (#{time.round(1)}ms)"
      generate_cache(@milestone, @worksheet, @link)
      @cache = false
    end

    render text: File.read(@cachepath)
  end

  def allow_iframe
    response.headers.except! 'X-Frame-Options'
  end

  def verify_signature(payload)
    signature = 'sha1=' + OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new('sha1'), BRIDGE_CONFIG['secret_token'].to_s, payload)
    Rack::Utils.secure_compare(signature, request.headers['X-Watchbot-Signature'].to_s)
  end

  def parse_notification(payload)
    notification = JSON.parse(payload)
    uri = URI.parse(Rack::Utils.unescape(notification['link']))
    link = uri.to_s.gsub('#' + uri.fragment, '')

    @worksheet = Bridge::GoogleSpreadsheet.new(BRIDGE_CONFIG['google_email'],
                                               BRIDGE_CONFIG['google_password'],
                                               BRIDGE_CONFIG['google_spreadsheet_id'],
                                               uri.fragment)

    @worksheet.notify_link_condition(link, notification['condition'])
  end
end
