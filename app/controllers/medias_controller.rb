require 'bridge_cache'
require 'bridge_error_codes'

class MediasController < ApplicationController
  include Bridge::Cache
  include MediasFilters

  after_action :allow_iframe, only: :embed
  before_filter :get_params, only: [:embed, :notify]
  before_filter :get_host
  before_filter :set_headers

  def embed
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
        get_object and return
        @object.parse_notification(@collection, @item, JSON.parse(payload))
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
    html = cache_path(@project, @collection, @item)

    unless File.exists?(html)
      get_object and return
      generate_cache(@object, @project, @collection, @item, @site)
    end

    if File.exists?(html)
      generate_screenshot_image
      @image.nil? ? render_error('Error', 'EXCEPTION', 400) : send_data(File.read(@image), type: 'image/png', disposition: 'inline')
    else
      render_error('Item not found (deleted, maybe?)', 'NOT_FOUND', 404)
    end
  end

  def render_embed_as_js
    @caller = request.original_url.gsub(/\?.*$/, '')
    @caller_path = request.fullpath.gsub(/\?.*$/, '')
    @url = @caller.gsub(/\.js.*$/, '')
    @path = [@project, @collection, @item].reject(&:blank?).join('-')
  end

  def render_embed_as_html
    get_object and return

    unless params[:template].blank?
      render_embed_from_template and return
    end

    @cachepath = cache_path(@project, @collection, @item)
    if BRIDGE_CONFIG['cache_embeds'] && File.exists?(@cachepath)
      @cache = true
    else
      generate_cache(@object, @project, @collection, @item, @site)
      @cache = false
    end

    logger.info "Rendering cache file #{@cachepath}"

    if File.exists?(@cachepath)
      render text: File.read(@cachepath)
    else
      render_error('Item not found (deleted, maybe?)', 'NOT_FOUND', 404)
    end
  end
end
