require File.join(File.expand_path(File.dirname(__FILE__)), '..', 'test_helper')
load File.join(File.expand_path(File.dirname(__FILE__)), '..', '..', 'lib', 'bridge_watchbot.rb')
require 'bridge_watchbot'

class BridgeWatchbotTest < ActiveSupport::TestCase

  def setup
    super
  end

  test "should initialize" do
    bot = Bridge::Watchbot.new('url' => 'http://localhost:3001')
    assert_kind_of String, bot.instance_variable_get(:@url)
    assert_kind_of URI, bot.instance_variable_get(:@uri)
  end

  test "should not send if url not set" do
    Rails.logger.expects(:info).with('Not sending to WatchBot because its URL is not set on the configuration file')
    Bridge::Watchbot.any_instance.expects(:request).never
    bot = Bridge::Watchbot.new
    bot.send('http://meedan.com')
  end

  test "should send if url is set" do
    Rails.logger.expects(:info).with('Sent to the WatchBot')
    bot = Bridge::Watchbot.new('url' => 'http://watch.bot/links')
    bot.send('http://meedan.com')
  end
end
