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
    file = File.join(Rails.root, 'public', 'cache', 'test.html')
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
    assert_equal 'http://test.host/medias/embed/test.js', assigns(:caller)
  end

  test "should list all milestones on index" do
    get :all
    assert_kind_of Bridge::GoogleSpreadsheet, assigns(:spreadsheet)
    assert_kind_of Array, assigns(:worksheets)
    assert_not_nil assigns(:worksheets).first.title
  end

  test "should return error if signature is not verified" do
    post :notify
    assert_response 400
    assert_equal Bridge::ErrorCodes::INVALID_SIGNATURE, JSON.parse(@response.body)['data']['code'] 
  end

  test "should return error if exception is thrown" do
    Rack::Utils.expects(:secure_compare).returns(true)
    post :notify
    assert_response 400
    assert_equal Bridge::ErrorCodes::EXCEPTION, JSON.parse(@response.body)['data']['code'] 
  end

  test "should return success when notified" do
    payload = { link: 'http://instagram.com/p/pwcow7AjL3/#test', condition: 'check404', timestamp: Time.now }.to_json
    sig = 'sha1=' + OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new('sha1'), BRIDGE_CONFIG['secret_token'], payload)
    @request.headers['X-Watchbot-Signature'] = sig
    post :notify, payload
    assert_response :success
  end

  test "should receive link" do
    get :embed, milestone: 'test', link: '183773d82423893d9409faf05941bdbd63eb0b5c', format: :html
    assert_equal '183773d82423893d9409faf05941bdbd63eb0b5c', assigns(:link)
    assert_match /test\/183773d82423893d9409faf05941bdbd63eb0b5c\.html$/, assigns(:cachepath)
  end
end
