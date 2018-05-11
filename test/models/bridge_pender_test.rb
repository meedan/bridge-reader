require File.join(File.expand_path(File.dirname(__FILE__)), '..', 'test_helper')
load File.join(File.expand_path(File.dirname(__FILE__)), '..', '..', 'lib', 'bridge_pender.rb')
require 'bridge_pender'

class BridgePenderTest < ActiveSupport::TestCase

  def setup
    super
    @b = Bridge::Pender.new(BRIDGE_CONFIG['pender_token'])
  end

  test "should initialize" do
    assert_not_nil @b.instance_variable_get(:@api)
  end

  test "should connect to the api" do
    assert_equal @b.instance_variable_get(:@api), @b.connect_to_api(BRIDGE_CONFIG['pender_token'])
  end

  test "should parse entries" do
    embeds = @b.parse_collection([{ link: 'https://twitter.com/caiosba/status/548252845238398976', id: 'test' },
                                  { link: 'http://instagram.com/p/BJvPAkxALcE/', id: 'test2' }])
    assert_equal 2, embeds.size
    assert_kind_of Hash, embeds.first[:oembed]
    assert_kind_of Hash, embeds.last[:oembed]
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
      @b.parse_collection([{ link: 'http://ca.ios.ba', id: 'test' }])
    end
  end

  test "should cache entries" do
    url = 'https://twitter.com/caiosba/status/290093908564779009'
    entry = { link: url, id: 'test' }
    key = 'pender:test'
    assert !Rails.cache.exist?(key)
    output = @b.parse_entry(entry)
    assert Rails.cache.exist?(key)
    assert_equal output, @b.parse_entry({ link: url, id: 'test' })
  end

  test "should alter Twitter response by adding ID" do
    link = 'https://twitter.com/caiosba/status/290093908564779009'
    c = @b.parse_collection([{ link: 'https://twitter.com/caiosba/status/290093908564779009', id: 'test' }])
    embed = c.first[:oembed]
    assert_equal '290093908564779009', embed['twitter_id']
  end

  test "should return unavailable and not crash if source post was removed" do
    entry = { link: 'https://twitter.com/statuses/634221052374188032', id: 'test' }
    assert_nothing_raised do
      entry = @b.parse_entry(entry)
    end
    assert entry[:oembed]['unavailable']
  end

  test "should parse non-link entry" do
    entry = { link: nil, id: 'test' }
    assert_nothing_raised do
      entry = @b.parse_entry(entry)
    end
    refute entry[:oembed]['unavailable']
  end
end
