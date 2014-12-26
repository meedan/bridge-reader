require File.join(File.expand_path(File.dirname(__FILE__)), '..', 'test_helper')

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

end
