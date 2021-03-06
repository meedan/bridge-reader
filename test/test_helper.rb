ENV["RAILS_ENV"] ||= "test"
require "codeclimate-test-reporter"
CodeClimate::TestReporter.start
require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'
require 'mocha/test_unit'
require 'webmock'
require 'capybara/rails'
require 'capybara/poltergeist'

class ActionDispatch::IntegrationTest
  include Capybara::DSL
end

class ActiveSupport::TestCase
  ActiveRecord::Migration.check_pending!

  def setup
    clear_cache
    WebMock.disable_net_connect! allow: ['codeclimate.com', 'api.embed.ly', 'api.twitter.com', 'instagram.com', 'www.google.com',
                                         'scontent.cdninstagram.com', 'spreadsheets.google.com', 'docs.google.com', BRIDGE_CONFIG['pender_base_url'].gsub(/^https?:\/\//, ''),
                                         'cc.meedan.com', 'speakbridge.io', 'raw.githubusercontent.com', 'localhost:3005', 
                                         '127.0.0.1', 'ca.ios.ba', 'api-ssl.bitly.com', 'api.bitly.com', 'www.googleapis.com', 'accounts.google.com', 'api.imgur.com']
    WebMock.stub_request(:post, 'http://watch.bot/links')
    WebMock.stub_request(:delete, /http:\/\/cc\.meedan\.com\/purge\?url=#{Regexp.escape(BRIDGE_CONFIG['bridgembed_host'])}.*/)
    WebMock.stub_request(:delete, /http:\/\/cc\.meedan\.com\/purge\?url=#{Regexp.escape(BRIDGE_CONFIG['bridgembed_host_private'])}.*/)
    Capybara.register_driver :poltergeist do |app|
      Capybara::Poltergeist::Driver.new(app, js_errors: false, timeout: 120, :phantomjs => Phantomjs.path)
    end
    Capybara.javascript_driver = :poltergeist
    Capybara.default_wait_time = 30
  end

  def teardown
    clear_cache
  end

  def stub_config(key, value)
    BRIDGE_CONFIG.each do |k, v|
      BRIDGE_CONFIG.stubs(:[]).with(k).returns(v)
    end
    BRIDGE_CONFIG.stubs(:[]).with(key.to_s).returns(value)
  end

  def stub_configs(configs)
    BRIDGE_CONFIG.each do |k, v|
      BRIDGE_CONFIG.stubs(:[]).with(k).returns(v)
    end
    configs.each do |key, value|
      BRIDGE_CONFIG.stubs(:[]).with(key.to_s).returns(value)
    end
  end

  def clear_cache
    Rails.cache.delete_matched /^[^\!]/
    FileUtils.rm_rf File.join(Rails.root, 'public', 'cache')
    FileUtils.rm_rf File.join(Rails.root, 'public', 'screenshots')
  end

  def cache_file_exists?(filename = 'test')
    File.exists?(File.join(Rails.root, 'public', 'cache', 'google_spreadsheet', filename + '.html'))
  end

  def create_cache
    dir = File.join(Rails.root, 'public', 'cache', 'google_spreadsheet')
    FileUtils.mkdir_p(dir) unless File.exists?(dir)
    FileUtils.touch(File.join(dir, 'test.html'))
    f = File.open(File.join(dir, 'test.html'), 'w+')
    f.puts('Test')
    f.close
  end

  def js
    Capybara.current_driver = Capybara.javascript_driver
    yield
    Capybara.current_driver = Capybara.default_driver
  end

  def with_testing_page(content)
    Capybara.current_driver = Capybara.javascript_driver
    name = 'test.html'
    dir = File.join(Rails.root, 'public', 'test')
    FileUtils.mkdir(dir) unless File.exists?(dir)
    f = File.open(File.join(dir, name), 'w+')
    f.puts '<!DOCTYPE html><html><head></head><body><h1>Test</h1>' + content + '</body></html>'
    f.close
    visit '/test/' + name + '?_=' + Time.now.to_i.to_s
    yield
    FileUtils.rm(File.join(dir, name), force: true)
    FileUtils.rmdir(dir)
    Capybara.current_driver = Capybara.default_driver
  end

  def with_testing_style(content)
    Capybara.current_driver = Capybara.javascript_driver
    name = 'test.css'
    dir = File.join(Rails.root, 'public', 'test')
    FileUtils.mkdir(dir) unless File.exists?(dir)
    f = File.open(File.join(dir, name), 'w+')
    f.puts content
    f.close
    yield
    FileUtils.rm(File.join(dir, name), force: true)
    FileUtils.rmdir(dir)
    Capybara.current_driver = Capybara.default_driver
  end

  def assert_same_image(actual_path, expected_path)
    actual, expected = MiniMagick::Image.new(actual_path).signature, MiniMagick::Image.new(expected_path).signature
    imgur = BRIDGE_CONFIG['imgur_client_id']
    link = actual_path
    
    if actual != expected && !imgur.blank?
      require 'imgur'
      client = Imgur.new(imgur)
      image = Imgur::LocalImage.new(actual_path, title: 'Test failed')
      uploaded = client.upload(image)
      link = uploaded.link
    end
    
    assert_equal actual, expected, "Generated image (#{link}) differs from expected (#{expected_path})"
  end

end
