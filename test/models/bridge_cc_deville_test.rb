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

  test "should clear cache from Cloudflare" do
    url = 'https://pender.checkmedia.org/api/medias.html?url=https://twitter.com/caiosba/status/811777768174260225'
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
