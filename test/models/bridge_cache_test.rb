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
    @b.generate_cache(@b, 'google_spreadsheet', 'watchbot', '')
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
    @b.generate_cache(@b, 'google_spreadsheet', 'watchbot', id)
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

  test "should not save blank file" do
    entry = {
      oembed: {},
      translations: [{ text: 'Test', comments: [] }] * 10
    }
    create_cache
    assert_not_nil File.size?(@b.cache_path('google_spreadsheet', 'test', ''))
    threads = []
    blank = nil
    threads << Thread.new do
      @b.send(:save_cache_file, @b, 'google_spreadsheet', 'test', '', 'collection', { collection: [entry] * 20 })
    end
    threads << Thread.new do
      sleep 1
      blank = File.size?(@b.cache_path('google_spreadsheet', 'test', ''))
    end
    threads.each{ |t| t.join }
    assert_not_nil blank
  end
end
