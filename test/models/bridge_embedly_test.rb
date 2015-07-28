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

  test "should parse entries" do
    embeds = @b.parse_collection([{ link: 'https://twitter.com/caiosba/status/548252845238398976', id: 'test' },
                                  { link: 'http://instagram.com/p/tP5h3kvHTi/', id: 'test2' }])
    assert_equal 2, embeds.size
    assert_kind_of Embedly::EmbedlyObject, embeds.first[:oembed]
    assert_kind_of Embedly::EmbedlyObject, embeds.last[:oembed]
  end

  test "should connect to Twitter" do
    assert_kind_of Twitter::REST::Client, @b.connect_to_twitter
  end

  test "should alter Twitter response by adding coordinates" do
    embed = @b.parse_collection([{ link: 'https://twitter.com/caiosba/status/290093908564779009', id: 'test' }]).first[:oembed]
    assert_kind_of Float, embed['coordinates'].first
    assert_kind_of Float, embed['coordinates'].last
  end

  test "should ignore if tweet does not exist" do
    embeds = []
    assert_nothing_raised do
      embeds = @b.parse_collection([{ link: 'https://twitter.com/caiosba/status/123456', id: 'test' }])
    end
    assert embeds.empty?
  end

  test "should ignore if tweet is private" do
    embeds = []
    assert_nothing_raised do
      embeds = @b.parse_collection([{ link: 'https://twitter.com/meglmz/status/490029122232782848', id: 'test' }])
    end
    assert embeds.empty?
  end

  test "should ignore if Instagram photo does not exist" do
    embeds = []
    assert_nothing_raised do
      embeds = @b.parse_collection([{ link: 'http://instagram.com/p/pwcow7AjL3/', id: 'test' }])
    end
    assert embeds.empty?
  end

  test "should alter Twitter response by getting the creation date" do
    embed = @b.parse_collection([{ link: 'https://twitter.com/caiosba/status/290093908564779009', id: 'test' }]).first[:oembed]
    assert_kind_of Time, embed['created_at']
  end

  test "should not crash if oembed has no provider" do
    assert_nothing_raised do
      @b.parse_collection([{ link: 'https://nothing.nothing', id: 'test' }]).first[:oembed]
    end
  end

  test "should cache entries" do
    url = 'https://twitter.com/caiosba/status/290093908564779009'
    entry = { link: url, id: 'test' }
    key = 'embedly:test'
    assert !Rails.cache.exist?(key)
    output = @b.parse_entry(entry)
    assert Rails.cache.exist?(key)
    assert_equal output, @b.parse_entry({ link: url, id: 'test' })
  end

  test "should alter Twitter response by adding ID" do
    embed = @b.parse_collection([{ link: 'https://twitter.com/caiosba/status/290093908564779009', id: 'test' }]).first[:oembed]
    assert_equal '290093908564779009', embed['twitter_id']
  end

  test "should wait if rate limit is reached" do
    Twitter::REST::Client.any_instance.stubs(:status).raises(Twitter::Error::TooManyRequests)
    Bridge::Embedly.any_instance.expects(:sleep).once
    @b.parse_collection([{ link: 'https://twitter.com/caiosba/status/290093908564779009', id: 'test' }]).first[:oembed]
  end

  test "should not wait if rate limit is not reached" do
    Bridge::Embedly.any_instance.expects(:sleep).never
    @b.parse_collection([{ link: 'https://twitter.com/caiosba/status/290093908564779009', id: 'test' }]).first[:oembed]
  end
end
