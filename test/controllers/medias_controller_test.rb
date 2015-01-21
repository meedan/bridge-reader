require File.join(File.expand_path(File.dirname(__FILE__)), '..', 'test_helper')
require 'w3c_validators'
include W3CValidators

class MediasControllerTest < ActionController::TestCase

  def setup
    super
    @controller = MediasController.new
    clear_cache
  end

  def teardown
    super
    clear_cache
  end

  test "should generate cache path" do
    assert !cache_file_exists?
    get :embed, milestone: 'test'
    assert_kind_of String, assigns(:cachepath)
    assert cache_file_exists?
  end

  test "should use cache if option is true and file exists" do
    stub_config :cache_embeds, true
    create_cache
    assert cache_file_exists?
    get :embed, milestone: 'test'
    assert assigns(:cache)
  end

  test "should not use cache if option is false" do
    stub_config :cache_embeds, false
    create_cache
    assert cache_file_exists?
    get :embed, milestone: 'test'
    assert !assigns(:cache)
  end

  test "should not use cache if option is true but file does not exist" do
    clear_cache
    stub_config :cache_embeds, true
    assert !cache_file_exists?
    get :embed, milestone: 'test'
    assert !assigns(:cache)
  end

  test "should output valid markup" do
    @validator = MarkupValidator.new
    clear_cache
    get :embed, milestone: 'test'
    file = Dir.glob(File.join(Rails.root, 'public', 'test_*')).first
    results = @validator.validate_file(file)
    if results.errors.length > 0
      results.errors.each do |err|
        puts err.to_s
      end
    end
    assert_equal 0, results.errors.length
  end

  test "should render javascript" do
    get :embed, milestone: 'test', format: :js
    assert_equal 'http://test.host/medias/embed/test', assigns(:url)
  end

  test "should list all milestones on index" do
    get :index
    assert_kind_of Bridge::GoogleSpreadsheet, assigns(:spreadsheet)
    assert_kind_of Array, assigns(:worksheets)
    assert_not_nil assigns(:worksheets).first.title
  end
end
