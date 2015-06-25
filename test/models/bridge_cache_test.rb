require File.join(File.expand_path(File.dirname(__FILE__)), '..', 'test_helper')
load File.join(File.expand_path(File.dirname(__FILE__)), '..', '..', 'lib', 'bridge_cache.rb')
require 'bridge_cache'

class TestObject
  include Bridge::Cache
end

class BridgeCacheTest < ActiveSupport::TestCase
  def setup
    super
    @b = TestObject.new
    @path = File.join(Rails.root, 'bin', 'phantomjs-' + (1.size * 8).to_s)
  end

  test "should return screenshoter" do
    assert_nothing_raised do
      assert_kind_of Smartshot::Screenshot, @b.screenshoter
    end
  end

  test "should fallback to system PhantomJS" do
    TestObject.any_instance.stubs(:`).returns('/usr/bin/phantomjs')
    TestObject.any_instance.stubs(:`).with("#{@path} --version").returns('Not valid')
    assert_nothing_raised do
      assert_kind_of Smartshot::Screenshot, @b.screenshoter
    end
  end

  test "should raise error if PhantomJS is not found at" do
    TestObject.any_instance.stubs(:`).returns('')
    assert_raises RuntimeError do
      @b.screenshoter
    end
  end
end
