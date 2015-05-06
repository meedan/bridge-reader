require File.join(File.expand_path(File.dirname(__FILE__)), '..', 'test_helper')
require 'w3c_validators'
include W3CValidators

class MediasControllerTest < ActionController::TestCase

  def setup
    super
    @controller = MediasController.new
  end

  test "should generate cache path" do
    assert !cache_file_exists?
    get :embed, type: 'milestone', id: 'test'
    assert_kind_of String, assigns(:cachepath)
    assert cache_file_exists?
  end

  test "should use cache if option is true and file exists" do
    stub_config :cache_embeds, true
    create_cache
    assert cache_file_exists?
    get :embed, type: 'milestone', id: 'test'
    assert assigns(:cache)
  end

  test "should not use cache if option is false" do
    stub_config :cache_embeds, false
    create_cache
    assert cache_file_exists?
    get :embed, type: 'milestone', id: 'test'
    assert !assigns(:cache)
  end

  test "should not use cache if option is true but file does not exist" do
    clear_cache
    stub_config :cache_embeds, true
    assert !cache_file_exists?
    get :embed, type: 'milestone', id: 'test'
    assert !assigns(:cache)
  end

  test "should output valid markup" do
    @validator = MarkupValidator.new
    clear_cache
    get :embed, type: 'milestone', id: 'test'
    file = File.join(Rails.root, 'public', 'cache', 'milestone', 'test.html')
    results = @validator.validate_file(file)
    if results.errors.length > 0
      results.errors.each do |err|
        puts err.to_s
      end
    end
    assert_equal 0, results.errors.length
  end

  test "should render javascript" do
    get :embed, type: 'milestone', id: 'test', format: :js
    assert_equal 'http://test.host/medias/embed/milestone/test', assigns(:url)
    assert_equal 'http://test.host/medias/embed/milestone/test.js', assigns(:caller)
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
    get :embed, type: 'link', id: 'c291f649aa5625b81322207177a41e2c4a08f09d', format: :html
    assert_equal 'c291f649aa5625b81322207177a41e2c4a08f09d', assigns(:id)
    assert_match /link\/c291f649aa5625b81322207177a41e2c4a08f09d\.html$/, assigns(:cachepath)
  end

  test "should render Twitter metatags" do
    get :embed, type: 'link', id: 'c291f649aa5625b81322207177a41e2c4a08f09d', format: :html
    assert_tag(tag: 'meta', attributes: { 'name' => 'twitter:image' })
    assert_tag(tag: 'meta', attributes: { 'name' => 'twitter:card' })
    assert_tag(tag: 'meta', attributes: { 'name' => 'twitter:site' })
  end

  test "should not render Twitter metatags" do
    get :embed, type: 'milestone', id: 'test', format: :html
    assert_no_tag(tag: 'meta', attributes: { 'name' => 'twitter:image' })
    assert_no_tag(tag: 'meta', attributes: { 'name' => 'twitter:card' })
    assert_no_tag(tag: 'meta', attributes: { 'name' => 'twitter:site' })
  end

  test "should not have object if type is not supported" do
    get :embed, type: 'invalid', id: 'invalid', format: :html
    assert_nil assigns(:object) 
  end

  test "should get error if type is not supported" do
    get :embed, type: 'invalid', id: 'invalid', format: :html
    assert_response 400
  end

  test "should not render png if type is not link" do
    get :embed, type: 'milestone', id: 'invalid', format: :png
    assert_response 400 
  end

  test "should render png for links" do
    path = File.join(Rails.root, 'public', 'screenshots', 'link', 'c291f649aa5625b81322207177a41e2c4a08f09d.png')
    assert !File.exists?(path)
    get :embed, type: 'link', id: 'c291f649aa5625b81322207177a41e2c4a08f09d', format: :png
    assert File.exists?(path)
  end

  test "should sanitize params" do
    get :embed, type: :link, id: 'another @thing!'
    assert_equal 'link', assigns(:type)
    assert_equal 'anotherthing', assigns(:id)
  end

  test "should render cached png" do
    Smartshot::Screenshot.expects(:new).never
    path = File.join(Rails.root, 'public', 'screenshots', 'link', 'c291f649aa5625b81322207177a41e2c4a08f09d.png')
    FileUtils.touch(path)
    assert File.exists?(path)
    get :embed, type: 'link', id: 'c291f649aa5625b81322207177a41e2c4a08f09d', format: :png
  end

  test "should render png for Twitter" do
    id = '183773d82423893d9409faf05941bdbd63eb0b5c'
    generated = File.join(Rails.root, 'public', 'screenshots', 'link', "#{id}.png")
    output = File.join(Rails.root, 'test', 'data', "#{id}.png")
    get :embed, type: 'link', id: id, format: :png
    assert FileUtils.compare_file(generated, output)
  end

  test "should render png for Instagram" do
    id = 'c291f649aa5625b81322207177a41e2c4a08f09d'
    generated = File.join(Rails.root, 'public', 'screenshots', 'link', "#{id}.png")
    output = File.join(Rails.root, 'test', 'data', "#{id}.png")
    get :embed, type: 'link', id: id, format: :png
    assert FileUtils.compare_file(generated, output)
  end

  test "should render png with custom CSS" do
    id = '183773d82423893d9409faf05941bdbd63eb0b5c'
    FileUtils.rm_rf File.join(Rails.root, 'public', 'screenshots', 'link', "#{id}.png")
    generated = File.join(Rails.root, 'public', 'screenshots', 'link', "#{id}.png")
    assert !File.exists?(generated)
    output = File.join(Rails.root, 'test', 'data', "#{id}-custom-css.png")
    get :embed, type: 'link', id: id, format: :png, css: 'http://ca.ios.ba/files/meedan/ooew.css'
    FileUtils.cp generated, '/tmp/generated'
    FileUtils.cp output, '/tmp/expected'
    assert FileUtils.compare_file(generated, output)
  end
end
