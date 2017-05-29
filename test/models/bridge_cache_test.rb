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

  test "should generate screenshot for Twitter" do
    id = '183773d82423893d9409faf05941bdbd63eb0b5c'
    @b.generate_cache(@b, 'google_spreadsheet', 'watchbot', id)
    Rails.cache.write('pender:' + id, { provider: 'twitter' })
    path = @b.screenshot_path('google_spreadsheet', 'watchbot', id)
    assert !File.exists?(path)
    @b.generate_screenshot('google_spreadsheet', 'watchbot', id)
    assert File.exists?(path)
  end

  test "should generate screenshot for Instagram" do
    Object.any_instance.stubs(:system).times(2)
    id = 'c291f649aa5625b81322207177a41e2c4a08f09d'
    @b.generate_cache(@b, 'google_spreadsheet', 'watchbot', id)
    Rails.cache.write('pender:' + id, { provider: 'instagram' })
    assert_not_nil @b.generate_screenshot('google_spreadsheet', 'watchbot', id)
    Object.any_instance.unstub(:system)
  end

  test "should check that cache exists" do
    assert !@b.cache_exists?('google_spreadsheet', 'watchbot', '')
    with_google_chrome do
      a = @b.generate_cache(@b, 'google_spreadsheet', 'watchbot', '')
      assert @b.cache_exists?('google_spreadsheet', 'watchbot', '')
    end
  end

  test "should check that screenshot exists" do
    assert !@b.screenshot_exists?('google_spreadsheet', 'watchbot', '')
    with_google_chrome do
      @b.generate_screenshot('google_spreadsheet', 'watchbot', '')
    end
    assert @b.screenshot_exists?('google_spreadsheet', 'watchbot', '')
  end

  test "should not crash if file does not exist" do
    assert !@b.cache_exists?('1', '2', '3')
    assert_nothing_raised do
      @b.clear_cache('1', '2', '3')
    end
  end

  test "should take screenshot of Arabic path" do
    with_google_chrome do
      assert_nothing_raised do
        @b.take_screenshot('https://bridge-embed.edge.meedan.com/medias/embed/you-stink-lebanon/%D8%B7%D9%84%D8%B9%D8%AA_%D8%B1%D9%8A%D8%AD%D8%AA%D9%83%D9%85-1/123.png', '/tmp/arabic.png')
      end
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

  %w(project collection item).each do |level|
    test "return empty array if bridge api return nil on request for #{level}" do
      myproject = Sources::BridgeApi.new('bridge_api', BRIDGE_PROJECTS['bridge-api'])
      myproject.send(:level_mapping, level).each do |l|
        myproject.expects("get_#{l}").with('general', '1').returns(nil)
      end
      assert_equal [], myproject.send(:get_entries_from_source, myproject, 'general', '1', level)
    end
  end
end
