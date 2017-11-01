require 'bridge_watchbot'

module SourcesHelper

  def notify_watchbot(url)
    Bridge::Watchbot.new(@config['watchbot']).send(url)
  end

  def get_title(title = '')
    @title = title unless title.blank?
    @title
  end

end
