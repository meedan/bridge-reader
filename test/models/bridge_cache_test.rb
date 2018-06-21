require File.join(File.expand_path(File.dirname(__FILE__)), '..', 'test_helper')
load File.join(File.expand_path(File.dirname(__FILE__)), '..', '..', 'lib', 'bridge_cache.rb')
require 'bridge_cache'

class BridgeCacheTest < ActiveSupport::TestCase
  def setup
    super
    @b = Sources::GoogleSpreadsheet.new('google_spreadsheet', BRIDGE_PROJECTS['google_spreadsheet'])
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

  test "should check that cache exists" do
    assert !@b.cache_exists?('google_spreadsheet', 'watchbot', '')
    @b.generate_cache(@b, 'watchbot', '')
    assert @b.cache_exists?('google_spreadsheet', 'watchbot', '')
  end

  test "should not crash if file does not exist" do
    assert !@b.cache_exists?('1', '2', '3')
    assert_nothing_raised do
      @b.clear_cache('1', '2', '3')
    end
  end

  test "should request cc-deville to clear cache for single item when generating cache" do
    id = 'cac1af59cc9b410752fcbe3810b36d30ed8e049d'
    Bridge::CcDeville.any_instance.expects(:clear_cache).with(BRIDGE_CONFIG['bridgembed_host'] + '/medias/embed/google_spreadsheet/watchbot/' + id).returns(201)
    @b.generate_cache(@b, 'watchbot', id)
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
    @b.generate_cache(@b, 'test', '')
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
    @b.generate_cache(@b, '', '')
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

  test "should not save blank file" do
    entry = {
      oembed: {},
      translations: [{ text: 'Test', comments: [] }] * 10
    }
    @b.instance_variable_set(:@source_entries, { collection: [entry] * 20 })
    create_cache
    cachepath = @b.cache_path('google_spreadsheet', 'test', '')
    assert_not_nil File.size?(cachepath)
    threads = []
    blank = nil
    threads << Thread.new do
      @b.send(:save_cache_file, @b, 'test', '')
    end
    threads << Thread.new do
      sleep 1
      blank = File.size?(@b.cache_path('google_spreadsheet', 'test', ''))
    end
    threads.each{ |t| t.join }
    assert_not_nil blank
  end

  test "should include css url hash on screenshot path" do
    css = 'http://ca.ios.ba/files/meedan/ooew.css'
    project, collection, id = 'google_spreadsheet', 'test', '183773d82423893d9409faf05941bdbd63eb0b5c'
    path = File.join(Rails.root, 'public', 'screenshots', project, collection, "#{id}.png")
    assert_equal path, @b.screenshot_path('google_spreadsheet', 'test', id)
    path_with_css = File.join(Rails.root, 'public', 'screenshots', project, collection, "#{id}-#{Digest::MD5.hexdigest(css.parameterize)}.png")
    assert_equal path_with_css, @b.screenshot_path('google_spreadsheet', 'test', id, css)
  end

  test "should also remove screenshot with css" do
    css = 'http://ca.ios.ba/files/meedan/ooew.css'
    project, collection, id = 'google_spreadsheet', 'test', '183773d82423893d9409faf05941bdbd63eb0b5c'
    test_file = File.join(Rails.root, 'test', 'data', '183773d82423893d9409faf05941bdbd63eb0b5c.png')
    path = @b.screenshot_path('google_spreadsheet', 'test', id)
    path_with_css = @b.screenshot_path('google_spreadsheet', 'test', id, css)
    dir = File.dirname(path)
    FileUtils.mkdir_p(dir) unless File.exists?(dir)

    FileUtils.cp(test_file, path)
    FileUtils.cp(test_file, path_with_css)
    assert File.exists?(path)
    assert File.exists?(path_with_css)

    @b.remove_screenshot('google_spreadsheet', 'test', id)
    assert !File.exists?(path)
    assert !File.exists?(path_with_css)
  end

  test "should raise error if can't take screenshot" do
    url = 'http://ca.ios.ba'
    params = { url: url }
    PenderClient::Request.stubs(:get_medias).with(BRIDGE_CONFIG['pender_base_url'], params, BRIDGE_CONFIG['pender_token']).returns({ 'data' => {'screenshot_taken' => 0}})
    assert_raise RuntimeError do
      error = @b.send(:take_screenshot, url, '/tmp/screenshot.png', 'item')
      assert_match /No screenshot received/, error
    end
  end
end
