ENV["RAILS_ENV"] ||= "test"
require "codeclimate-test-reporter"
CodeClimate::TestReporter.start
require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'
require 'mocha/test_unit'

class ActiveSupport::TestCase
  ActiveRecord::Migration.check_pending!

  def stub_config(key, value)
    BRIDGE_CONFIG.each do |k, v|
      BRIDGE_CONFIG.stubs(:[]).with(k).returns(v)
    end
    BRIDGE_CONFIG.stubs(:[]).with(key.to_s).returns(value)
  end

  def clear_cache
    FileUtils.rm Dir.glob(File.join(Rails.root, 'public', 'test_*'))
  end

  def cache_file_exists?
    !Dir.glob(File.join(Rails.root, 'public', 'test_*')).empty?
  end

  def create_cache
    Bridge::GoogleSpreadsheet.any_instance.stubs(:updated_at).returns(123456)
    FileUtils.touch(File.join(Rails.root, 'public', 'test_123456.html'))
  end
end
