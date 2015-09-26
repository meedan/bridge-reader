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
    Sources::GoogleSpreadsheet.any_instance.stubs(:`).with("/usr/bin/phantomjs --version").returns('2.0.0')
    assert_nothing_raised do
      assert_kind_of Smartshot::Screenshot, @b.screenshoter
    end
  end

  test "should raise error if PhantomJS is not found" do
    Sources::GoogleSpreadsheet.any_instance.stubs(:`).returns('/usr/bin/phantomjs')
    Sources::GoogleSpreadsheet.any_instance.stubs(:`).with("#{@path} --version").returns('Not valid')
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

  test "should not crash if file does not exist" do
    assert !@b.cache_exists?('1', '2', '3')
    assert_nothing_raised do
      @b.clear_cache('1', '2', '3')
    end
  end

  test "should take screenshot of Arabic path" do
    assert_nothing_raised do
      @b.take_screenshot('https://bridge-embed.edge.meedan.com/medias/embed/you-stink-lebanon/%D8%B7%D9%84%D8%B9%D8%AA_%D8%B1%D9%8A%D8%AD%D8%AA%D9%83%D9%85-1/123.png', ['body'], [], '/tmp/arabic.png', 'item')
    end
  end

  test "should request cc-deville to clear cache for single item when generating cache" do
    id = 'c291f649aa5625b81322207177a41e2c4a08f09d'
    Bridge::CcDeville.any_instance.expects(:clear_cache).with(BRIDGE_CONFIG['bridgembed_host'] + '/medias/embed/google_spreadsheet/test/' + id).returns(201)
    @b.generate_cache(@b, 'google_spreadsheet', 'test', id)
  end

  test "should request cc-deville to clear cache for single item when removing cache" do
    Bridge::CcDeville.any_instance.expects(:clear_cache).with(BRIDGE_CONFIG['bridgembed_host'] + '/medias/embed/1/2/3').returns(201)
    @b.clear_cache('1', '2', '3')
  end

  test "should request cc-deville to clear cache for single item when removing screenshot" do
    Bridge::CcDeville.any_instance.expects(:clear_cache).with(BRIDGE_CONFIG['bridgembed_host'] + '/medias/embed/1/2/3.png').returns(201)
    @b.remove_screenshot('1', '2', '3')
  end

  test "should request cc-deville to clear cache for collection when generating cache" do
    Bridge::CcDeville.any_instance.expects(:clear_cache).with(BRIDGE_CONFIG['bridgembed_host'] + '/medias/embed/google_spreadsheet/test').returns(201)
    @b.generate_cache(@b, 'google_spreadsheet', 'test', '')
  end

  test "should request cc-deville to clear cache for collection when removing cache" do
    Bridge::CcDeville.any_instance.expects(:clear_cache).with(BRIDGE_CONFIG['bridgembed_host'] + '/medias/embed/1/2').returns(201)
    @b.clear_cache('1', '2', '')
  end

  test "should request cc-deville to clear cache for collection when removing screenshot" do
    Bridge::CcDeville.any_instance.expects(:clear_cache).with(BRIDGE_CONFIG['bridgembed_host'] + '/medias/embed/1/2.png').returns(201)
    @b.remove_screenshot('1', '2', '')
  end

  test "should request cc-deville to clear cache for project when generating cache" do
    Bridge::CcDeville.any_instance.expects(:clear_cache).with(BRIDGE_CONFIG['bridgembed_host'] + '/medias/embed/google_spreadsheet').returns(201)
    @b.generate_cache(@b, 'google_spreadsheet', '', '')
  end

  test "should request cc-deville to clear cache for project when removing cache" do
    Bridge::CcDeville.any_instance.expects(:clear_cache).with(BRIDGE_CONFIG['bridgembed_host'] + '/medias/embed/1').returns(201)
    @b.clear_cache('1', '', '')
  end

  test "should request cc-deville to clear cache for project when removing screenshot" do
    Bridge::CcDeville.any_instance.expects(:clear_cache).with(BRIDGE_CONFIG['bridgembed_host'] + '/medias/embed/1.png').returns(201)
    @b.remove_screenshot('1', '', '')
  end

  test "should not request cc-deville if configuration is blank" do
    stub_config 'cc_deville_host', ''
    Bridge::CcDeville.expects(:new).never
    @b.clear_cache('1', '', '')
  end
end
