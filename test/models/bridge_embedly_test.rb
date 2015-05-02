require File.join(File.expand_path(File.dirname(__FILE__)), '..', 'test_helper')
load File.join(File.expand_path(File.dirname(__FILE__)), '..', '..', 'lib', 'bridge_embedly.rb')
require 'bridge_embedly'

class BridgeEmbedlyTest < ActiveSupport::TestCase

  def setup
    super
    @b = Bridge::Embedly.new(BRIDGE_CONFIG['embedly_key'])
  end

  test "should initialize" do
    assert_not_nil @b.instance_variable_get(:@api)
  end

  test "should connect to the api" do
    assert_equal @b.instance_variable_get(:@api), @b.connect_to_api(BRIDGE_CONFIG['embedly_key'])
  end

  test "should get objects from URLs" do
    embeds = @b.objects_from_urls(['https://twitter.com/caiosba/status/548252845238398976', 'https://instagram.com/p/tP5h3kvHTi/'])
    assert_equal 2, embeds.size
    assert_kind_of Embedly::EmbedlyObject, embeds.first
    assert_kind_of Embedly::EmbedlyObject, embeds.last
  end

  test "should parse entries" do
    embeds = @b.parse_entries([{ link: 'https://twitter.com/caiosba/status/548252845238398976' },
                               { link: 'http://instagram.com/p/tP5h3kvHTi/' }])
    assert_equal 2, embeds.size
    assert_kind_of Embedly::EmbedlyObject, embeds.first[:oembed]
    assert_kind_of Embedly::EmbedlyObject, embeds.last[:oembed]
  end

  test "should connect to Twitter" do
    assert_kind_of Twitter::REST::Client, @b.connect_to_twitter
  end

  test "should alter Twitter response by adding coordinates" do
    embed = @b.parse_entries([{ link: 'https://twitter.com/caiosba/status/290093908564779009' }]).first[:oembed]
    assert_kind_of Float, embed['coordinates'].first
    assert_kind_of Float, embed['coordinates'].last
  end

  test "should ignore if tweet does not exist" do
    embeds = []
    assert_nothing_raised do
      embeds = @b.parse_entries([{ link: 'https://twitter.com/caiosba/status/123456' }])
    end
    assert embeds.empty?
  end

  test "should ignore if tweet is private" do
    embeds = []
    assert_nothing_raised do
      embeds = @b.parse_entries([{ link: 'https://twitter.com/meglmz/status/490029122232782848' }])
    end
    assert embeds.empty?
  end

  test "should ignore if Instagram photo does not exist" do
    embeds = []
    assert_nothing_raised do
      embeds = @b.parse_entries([{ link: 'http://instagram.com/p/pwcow7AjL3/' }])
    end
    assert embeds.empty?
  end

  test "should alter Twitter response by getting the creation date" do
    embed = @b.parse_entries([{ link: 'https://twitter.com/caiosba/status/290093908564779009' }]).first[:oembed]
    assert_kind_of Time, embed['created_at']
  end

  test "should not crash if oembed has no provider" do
    assert_nothing_raised do
      @b.parse_entries([{ link: 'https://nothing.nothing' }]).first[:oembed]
    end
  end

  test "should generate cache key" do
    url = 'https://twitter.com/caiosba/status/290093908564779009'
    entry = { link: url }
    key = @b.bridge_cache_key(entry)
    assert_kind_of String, key
    assert_equal key, @b.bridge_cache_key(entry)
  end

  test "should cache entries" do
    Rails.cache.expects(:delete_matched).once
    url = 'https://twitter.com/caiosba/status/290093908564779009'
    entry = { link: url }
    key = @b.bridge_cache_key(entry)
    assert !Rails.cache.exist?(key)
    output = @b.parse_entry(entry)
    assert Rails.cache.exist?(key)
    assert_equal output, @b.parse_entry({ link: url })
  end

  test "should notify the watchbot when some link is online" do
    Bridge::Embedly.any_instance.expects(:send_to_watchbot).once
    entry = { link: 'http://twitter.com/caiosba/123456' }
    @b.notify_available(entry)
  end

  test "should not notify watchbot if configuration option is not set" do
    Bridge::Watchbot.any_instance.expects(:request).never
    Rails.logger.expects(:info).with('Not sending to WatchBot because its URL is not set on the configuration file')
    stub_config('watchbot_url', nil)
    @b.send_to_watchbot({ link: 'http://twitter.com/caiosba/123456' })
  end

  test "should send link to watchbot" do
    Rails.logger.expects(:info).with('Sent to the WatchBot')
    @b.send_to_watchbot({ link: 'https://twitter.com/caiosba/123456', source: 'milestone' })
    WebMock.assert_requested :post, BRIDGE_CONFIG['watchbot_url'], body: 'url=https%3A%2F%2Ftwitter.com%2Fcaiosba%2F123456%23milestone'
  end

  test "should remove screenshot of embed" do
    dir = File.join(Rails.root, 'public', 'screenshots', 'link')
    FileUtils.mkdir_p(dir) unless File.exists?(dir)
    path = File.join(dir, '183773d82423893d9409faf05941bdbd63eb0b5c.png')
    FileUtils.touch(path)
    assert File.exists?(path)
    @b.remove_embed_screenshot({ link: 'https://twitter.com/caiosba/status/548252845238398976' })
    assert !File.exists?(path)
  end
end
