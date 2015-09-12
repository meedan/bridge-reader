ENV["RAILS_ENV"] ||= "test"
require "codeclimate-test-reporter"
CodeClimate::TestReporter.start
require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'
require 'mocha/test_unit'
require 'webmock/test_unit'
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
                                         'scontent.cdninstagram.com', 'spreadsheets.google.com', 'docs.google.com', /cc.test.meedan.com.*speakbridge\.io/,
                                         '127.0.0.1', 'ca.ios.ba', 'api-ssl.bitly.com', 'www.googleapis.com', 'accounts.google.com']
    WebMock.stub_request(:post, 'http://watch.bot/links')
    WebMock.stub_request(:delete, /http:\/\/cc\.test\.meedan\.com\/purge\?url=#{Regexp.escape(BRIDGE_CONFIG['bridgembed_host'])}.*/)
    WebMock.stub_request(:delete, /http:\/\/cc\.test\.meedan\.com\/purge\?url=#{Regexp.escape(BRIDGE_CONFIG['bridgembed_host_private'])}.*/)
    Capybara.register_driver :poltergeist do |app|
      Capybara::Poltergeist::Driver.new(app, js_errors: false)
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

  def clear_cache
    Rails.cache.delete_matched /^[^\!]/
    FileUtils.rm_rf File.join(Rails.root, 'public', 'cache')
    FileUtils.rm_rf File.join(Rails.root, 'public', 'screenshots')
  end

  def cache_file_exists?
    File.exists?(File.join(Rails.root, 'public', 'cache', 'google_spreadsheet', 'test.html'))
  end

  def create_cache
    dir = File.join(Rails.root, 'public', 'cache', 'google_spreadsheet')
    FileUtils.mkdir_p(dir) unless File.exists?(dir)
    FileUtils.touch(File.join(dir, 'test.html'))
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
    visit '/test/' + name
    assert page.find('iframe').visible?
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
end
