require File.join(File.expand_path(File.dirname(__FILE__)), '..', 'test_helper')
load File.join(File.expand_path(File.dirname(__FILE__)), '..', '..', 'lib', 'bridge_embedly.rb')
require 'bridge_embedly'

class BridgeEmbedlyTest < ActiveSupport::TestCase

  def setup
    @b = Bridge::Embedly.new(BRIDGE_CONFIG['embedly_key'])
  end

  test "should initialize" do
    assert_not_nil @b.instance_variable_get(:@api)
  end

  test "should connect to the api" do
    assert_equal @b.instance_variable_get(:@api), @b.connect_to_api(BRIDGE_CONFIG['embedly_key'])
  end

  test "should get objects from URLs" do
    embeds = @b.objects_from_urls(['https://twitter.com/caiosba/status/548252845238398976', 'http://instagram.com/p/tP5h3kvHTi/'])
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
    assert_nothing_raised do
      @b.parse_entries([{ link: 'https://twitter.com/caiosba/status/123456' }])
    end
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
end
