require File.join(File.expand_path(File.dirname(__FILE__)), '..', 'test_helper')
load File.join(File.expand_path(File.dirname(__FILE__)), '..', '..', 'lib', 'bridge_cache.rb')
require 'bridge_cache'

class BaseScreenshotTest < ActiveSupport::TestCase
  def setup
    super
    @b = Sources::GoogleSpreadsheet.new('google_spreadsheet', BRIDGE_PROJECTS['google_spreadsheet'])
  end

  test "should generate screenshot for Twitter" do
    skip('Skip screenshot test')
    id = '183773d82423893d9409faf05941bdbd63eb0b5c'
    @b.generate_cache(@b, 'test', id)
    path = @b.screenshot_path('google_spreadsheet', 'test', id)
    assert !File.exists?(path)
    @b.generate_screenshot('google_spreadsheet', 'test', id)
    assert File.exists?(path)
  end

  test "should generate screenshot for Instagram" do
    skip('Skip screenshot test')
    id = '4152e40dcbab622b12dfd56f2d91f6e19813c66d'
    @b.generate_cache(@b, 'watchbot', id)
    path = @b.screenshot_path('google_spreadsheet', 'watchbot', id)
    assert !File.exists?(path)
    @b.generate_screenshot('google_spreadsheet', 'watchbot', id)
    assert File.exists?(path)
  end

  test "should check that screenshot exists" do
    skip('Skip screenshot test')
    id = '4152e40dcbab622b12dfd56f2d91f6e19813c66d'
    @b.generate_cache(@b, 'watchbot', id)
    assert !@b.screenshot_exists?('google_spreadsheet', 'watchbot', id)
    @b.generate_screenshot('google_spreadsheet', 'watchbot', id)
    assert @b.screenshot_exists?('google_spreadsheet', 'watchbot', id)
  end

  test "should take screenshot of Arabic path" do
    skip('Skip screenshot test')
    url = 'https://ar.wikipedia.org/wiki/%D8%A7%D9%84%D8%B5%D9%81%D8%AD%D8%A9_%D8%A7%D9%84%D8%B1%D8%A6%D9%8A%D8%B3%D9%8A%D8%A9'
    assert_nothing_raised do
      @b.send(:take_screenshot, url, '/tmp/arabic.png', 'item')
    end
  end
end
