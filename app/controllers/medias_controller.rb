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
      verify_signature(payload) and return
      get_object
      render_not_found and return if @object.nil?
      @object.parse_notification(@collection, @item, JSON.parse(payload))
      render_success
    rescue Exception => e
      render_error e.message, 'EXCEPTION'
    end
  end

  private

  def render_embed_as_png
    ignore_non_items and return
    html_path = cache_path(@project, @collection, @item, 'screenshot')
    cache = verify_html_cache(html_path, 'screenshot')

    if screenshot_exists?(@project, @collection, @item, @css)
      file = screenshot_path(@project, @collection, @item, @css)
      send_data(File.read(file), type: 'image/png', disposition: 'inline')
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
    ignore_non_items and return
    get_object and return
    render_not_found and return if @object.nil?

    @url = request.original_url

    render_embed_from_template and return
    @cachepath = cache_path(@project, @collection, @item, @template)
    @cache = verify_html_cache(@cachepath, @template)
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

  def ignore_non_items
    return if request.format.html? && @template.blank?
    level = get_level(@project, @collection, @item)
    render_not_found and return true if level != 'item'
  end

  def verify_html_cache(html_path, template = '')
    return true if File.exists?(html_path) && BRIDGE_CONFIG['cache_embeds']
    get_object if @object.nil?
    unless generate_cache(@object, @collection, @item, template)
      logger.info "Could not generate cache on #{html_path}"
    end
    return false
  end

  def handle_new_html_cache(cache)
    if !cache || !screenshot_exists?(@project, @collection, @item, @css)
      generate_screenshot_image
      render_error('Error', 'EXCEPTION', 400) and return true if @image.nil?
    end
  end

end
