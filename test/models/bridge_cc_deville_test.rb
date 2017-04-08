require File.join(File.expand_path(File.dirname(__FILE__)), '..', 'test_helper')
load File.join(File.expand_path(File.dirname(__FILE__)), '..', '..', 'lib', 'bridge_cc_deville.rb')
require 'bridge_cc_deville'

class BridgeCcDevilleTest < ActiveSupport::TestCase
  def setup
    super
    @b = Bridge::CcDeville.new(BRIDGE_CONFIG['cc_deville_host'], BRIDGE_CONFIG['cc_deville_token'], BRIDGE_CONFIG['cc_deville_httpauth'])
  end

  test "should instantiate" do
    assert_kind_of Bridge::CcDeville, @b
  end

  test "should clear cache from Varnish" do
    # FIXME: Assumption that this path exists
    url = 'https://speakbridge.io/medias/embed/test/749262715138323/193'
    Net::HTTP.get_response(URI.parse(url))
    sleep 2

    status = @b.get_status(url)
    varnish = status['data']['caches'].first
    assert_equal 'varnish-lira', varnish['name']
    assert_equal 'HIT', varnish['cache_status']
    assert_not_equal 0, varnish['age']

    @b.clear_cache(url)
    sleep 2

    status = @b.get_status(url)
    varnish = status['data']['caches'].first
    assert_equal 'varnish-lira', varnish['name']
    assert_equal 'MISS', varnish['cache_status']
    assert_equal 0, varnish['age'].to_i
  end

  test "should clear cache from Cloudflare" do
    # FIXME: Assumption that this path exists
    # Cloudflare is more about assets (JS, images, CSS, etc.)
    url = 'https://speakbridge.io/stylesheets/bridge.css'

    status = @b.get_status(url)
    cf = status['data']['caches'].last
    assert_equal 'cloudflare', cf['name']
    old_expiration_time = Time.parse(cf['expires'])

    @b.clear_cache(url)
    sleep 2

    status = @b.get_status(url)
    cf = status['data']['caches'].last
    assert_equal 'cloudflare', cf['name']
    new_expiration_time = Time.parse(cf['expires'])

    assert new_expiration_time > old_expiration_time
  end
end
