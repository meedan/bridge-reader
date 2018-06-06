require 'bridge_cache'
require 'bridge_error_codes'

class MediasController < ApplicationController
  include Bridge::Cache
  include MediasFilters

  after_action :allow_iframe, only: :embed
  before_filter :ignore_user_agents
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
        get_object
        render_not_found and return if @object.nil?
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
      get_object
      generate_cache(@object, @project, @collection, @item, @site) if @object
    end
    if File.exists?(html)
      generate_screenshot_image
      render_error('Error', 'EXCEPTION', 400) and return if @image.nil?
    end

    if screenshot_exists?(@project, @collection, @item, @css)
      @image = screenshot_path(@project, @collection, @item, @css) if @image.nil?
      send_data(File.read(@image), type: 'image/png', disposition: 'inline')
    else
      logger.info "Could not find image on #{@image}"
      render_not_found
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
    render_not_found and return if @object.nil?
      
    @url = request.original_url

    unless params[:template].blank?
      render_embed_from_template and return
    end

    @cachepath = cache_path(@project, @collection, @item)
    if BRIDGE_CONFIG['cache_embeds'] && File.exists?(@cachepath)
      @cache = true
    else
      unless generate_cache(@object, @project, @collection, @item, @site)
        logger.info "Could not generate cache on #{@cachepath}"
      end
      @cache = false
    end

    render_cache(@cachepath)
  end

  def render_cache(cachepath)
    if File.exists?(cachepath)
      logger.info "Rendering cache file #{cachepath}"
      content = post_process_cache(File.read(cachepath))
      render text: content
    else
      logger.info "Could not render cache file #{cachepath}"
      render_not_found
    end
  end

  def ignore_user_agents
    # Slackbot-LinkExpanding 1.0 (+https://api.slack.com/robots)
    if !request.user_agent.blank? && !BRIDGE_CONFIG['ignore_user_agents'].blank? && request.user_agent.match(/#{Regexp.quote(BRIDGE_CONFIG['ignore_user_agents'])}/)
      render_success and return
    end
  end
end
