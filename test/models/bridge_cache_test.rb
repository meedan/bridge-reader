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

  test "should clear cache" do
    path = @b.cache_path('link', 'test')
    FileUtils.touch(path)
    assert File.exists?(path)
    @b.clear_cache('link', 'test')
    assert !File.exists?(path)
  end

  test "should generate screenshot for Twitter" do
    id = '183773d82423893d9409faf05941bdbd63eb0b5c'
    Rails.cache.write(id, { url: 'https://twitter.com/caiosba/status/548252845238398976', title: 'test' })
    path = @b.cache_path('link', id)
    assert !File.exists?(path)
    @b.generate_screenshot('link', id)
    assert File.exists?(path)
  end

  test "should generate screenshot for Instagram" do
    id = 'c291f649aa5625b81322207177a41e2c4a08f09d'
    Rails.cache.write(id, { url: 'http://instagram.com/p/tP5h3kvHTi/', title: 'test' })
    path = @b.cache_path('link', id)
    assert !File.exists?(path)
    @b.generate_screenshot('link', id)
    assert File.exists?(path)
  end
end
