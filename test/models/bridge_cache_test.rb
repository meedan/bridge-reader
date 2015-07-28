require File.join(File.expand_path(File.dirname(__FILE__)), '..', 'test_helper')
load File.join(File.expand_path(File.dirname(__FILE__)), '..', '..', 'lib', 'bridge_cache.rb')
require 'bridge_cache'

class BridgeCacheTest < ActiveSupport::TestCase
  def setup
    super
    @b = Sources::GoogleSpreadsheet.new('google_spreadsheet', BRIDGE_PROJECTS['google_spreadsheet'])
    @path = File.join(Rails.root, 'bin', 'phantomjs-' + (1.size * 8).to_s)
  end

  test "should return screenshoter" do
    assert_nothing_raised do
      assert_kind_of Smartshot::Screenshot, @b.screenshoter
    end
  end

  test "should fallback to system PhantomJS" do
    Sources::GoogleSpreadsheet.any_instance.stubs(:`).returns('/usr/bin/phantomjs')
    Sources::GoogleSpreadsheet.any_instance.stubs(:`).with("#{@path} --version").returns('Not valid')
    assert_nothing_raised do
      assert_kind_of Smartshot::Screenshot, @b.screenshoter
    end
  end

  test "should raise error if PhantomJS is not found at" do
    Sources::GoogleSpreadsheet.any_instance.stubs(:`).returns('')
    assert_raises RuntimeError do
      @b.screenshoter
    end
  end

  test "should clear cache" do
    path = @b.cache_path('google_spreadsheet', 'test', 'item')
    dir = File.dirname(path)
    FileUtils.mkdir_p(dir) unless File.exists?(dir)
    FileUtils.touch(path)
    assert File.exists?(path)
    @b.clear_cache('google_spreadsheet', 'test', 'item')
    assert !File.exists?(path)
  end

  test "should generate screenshot for Twitter" do
    id = '183773d82423893d9409faf05941bdbd63eb0b5c'
    @b.generate_cache(@b, 'google_spreadsheet', 'test', id)
    Rails.cache.write('embedly:' + id, { provider: 'twitter' })
    path = @b.screenshot_path('google_spreadsheet', 'test', id)
    assert !File.exists?(path)
    @b.generate_screenshot('google_spreadsheet', 'test', id)
    assert File.exists?(path)
  end

  test "should generate screenshot for Instagram" do
    id = 'c291f649aa5625b81322207177a41e2c4a08f09d'
    @b.generate_cache(@b, 'google_spreadsheet', 'test', id)
    Rails.cache.write('embedly:' + id, { provider: 'instagram' })
    path = @b.screenshot_path('google_spreadsheet', 'test', id)
    assert !File.exists?(path)
    @b.generate_screenshot('google_spreadsheet', 'test', id)
    assert File.exists?(path)
  end

  test "should check that cache exists" do
    assert !@b.cache_exists?('google_spreadsheet', 'test', '')
    @b.generate_cache(@b, 'google_spreadsheet', 'test', '')
    assert @b.cache_exists?('google_spreadsheet', 'test', '')
  end

  test "should check that screenshot exists" do
    assert !@b.screenshot_exists?('google_spreadsheet', 'test', '')
    @b.generate_screenshot('google_spreadsheet', 'test', '')
    assert @b.screenshot_exists?('google_spreadsheet', 'test', '')
  end
end
