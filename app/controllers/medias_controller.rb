require 'bridge_google_spreadsheet'
require 'bridge_embedly'
require 'bridge_cache'
require 'bridge_error_codes'

class MediasController < ApplicationController
  include Bridge::Cache

  after_action :allow_iframe, only: :embed
  before_filter :get_host
  before_filter :get_params, only: :embed

  TYPES = ['milestone', 'link']

  def all
    @spreadsheet = Bridge::GoogleSpreadsheet.new(BRIDGE_CONFIG['google_email'],
                                                 BRIDGE_CONFIG['google_password'],
                                                 BRIDGE_CONFIG['google_spreadsheet_id'])
    @worksheets = @spreadsheet.get_worksheets
  end

  def embed
    render_error('Type not supported', 'INVALID_TYPE') and return if @type.nil?

    respond_to do |format|
      format.html { render_embed_as_html           }
      format.js   { render_embed_as_js             }
      format.png  { render_embed_as_png and return }
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

  def render_embed_as_png
    render_error('Link is mandatory', 'PARAMETERS_MISSING') and return unless @type == 'link'

    css = URI.parse(params[:css].to_s).to_s

    @image = generate_screenshot(@type, @id, css)
    send_data File.read(@image), type: 'image/png', disposition: 'inline'
  end

  def render_embed_as_js
    @caller = request.original_url
    @url = @caller.gsub(/\.js$/, '')
  end

  def render_embed_as_html
    @cachepath = cache_path(@type, @id)
    if BRIDGE_CONFIG['cache_embeds'] && File.exists?(@cachepath)
      @cache = true
    else
      get_object
      generate_cache(@object, @type, @id, @site)
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

  def get_params
    @type = (TYPES & [params[:type].to_s]).first
    @id = params[:id].to_s.gsub(/[^a-zA-Z0-9_-]/, '')
  end

  def get_object
    case @type.to_s
    when 'milestone'
      @object = Bridge::GoogleSpreadsheet.new(BRIDGE_CONFIG['google_email'],
                                              BRIDGE_CONFIG['google_password'],
                                              BRIDGE_CONFIG['google_spreadsheet_id'],
                                              @id)
    when 'link'
      @object = Bridge::GoogleSpreadsheet.new(BRIDGE_CONFIG['google_email'],
                                              BRIDGE_CONFIG['google_password'],
                                              BRIDGE_CONFIG['google_spreadsheet_id'])
      @link = @object.get_link(@id)
    end
  end

  def get_host
    @host = request.host
    @host_with_port = request.host_with_port
    @protocol = request.protocol
    @site = @protocol + @host_with_port
  end
end
