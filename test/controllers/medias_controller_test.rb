require File.join(File.expand_path(File.dirname(__FILE__)), '..', 'test_helper')

class MediasControllerTest < ActionController::TestCase

  def setup
    super
    @controller = MediasController.new
  end

  test "should generate cache path" do
    assert !cache_file_exists?
    get :embed, project: 'google_spreadsheet', collection: 'test'
    assert_kind_of String, assigns(:cachepath)
    assert cache_file_exists?
  end

  test "should use cache if option is true and file exists" do
    stub_config :cache_embeds, true
    create_cache
    assert cache_file_exists?
    get :embed, project: 'google_spreadsheet', collection: 'test'
    assert assigns(:cache)
  end

  test "should not use cache if option is false" do
    stub_config :cache_embeds, false
    create_cache
    assert cache_file_exists?
    get :embed, project: 'google_spreadsheet', collection: 'test'
    assert !assigns(:cache)
  end

  test "should not use cache if option is true but file does not exist" do
    clear_cache
    stub_config :cache_embeds, true
    assert !cache_file_exists?
    get :embed, project: 'google_spreadsheet', collection: 'test'
    assert !assigns(:cache)
  end

  test "should output valid markup" do
    require 'html_validation'
    h = PageValidations::HTMLValidation.new
    clear_cache
    get :embed, project: 'google_spreadsheet', collection: 'test'
    file = File.join(Rails.root, 'public', 'cache', 'google_spreadsheet', 'test.html')
    v = h.validation(File.read(file), BRIDGE_CONFIG['bridgembed_host'])
    assert v.valid?, v.exceptions
  end

  test "should render javascript" do
    get :embed, project: 'google_spreadsheet', collection: 'test', format: :js
    assert_equal 'http://test.host/medias/embed/google_spreadsheet/test', assigns(:url)
    assert_equal 'http://test.host/medias/embed/google_spreadsheet/test.js', assigns(:caller)
  end

  test "should return error if signature is not verified" do
    post :notify, project: 'google_spreadsheet'
    assert_response 400
    assert_equal Bridge::ErrorCodes::INVALID_SIGNATURE, JSON.parse(@response.body)['data']['code'] 
  end

  test "should return error if exception is thrown" do
    Rack::Utils.expects(:secure_compare).returns(true)
    post :notify, project: 'google_spreadsheet'
    assert_response 400
    assert_equal Bridge::ErrorCodes::EXCEPTION, JSON.parse(@response.body)['data']['code'] 
  end

  test "should return success when notified" do
    payload = { link: 'http://instagram.com/p/pwcow7AjL3/#test', condition: 'check404', timestamp: Time.now }.to_json
    sig = 'sha1=' + OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new('sha1'), BRIDGE_CONFIG['secret_token'], payload)
    @request.headers['X-Signature'] = sig
    @request.env['RAW_POST_DATA'] = payload
    post :notify, project: 'google_spreadsheet'
    @request.env.delete('RAW_POST_DATA')
    assert_response :success
  end

  test "should receive item" do
    get :embed, project: 'google_spreadsheet', collection: 'test', item: 'c291f649aa5625b81322207177a41e2c4a08f09d', format: :html
    assert_equal 'c291f649aa5625b81322207177a41e2c4a08f09d', assigns(:item)
    assert_match /test\/c291f649aa5625b81322207177a41e2c4a08f09d\.html$/, assigns(:cachepath)
  end

  test "should render Twitter metatags" do
    get :embed, project: 'google_spreadsheet', collection: 'test', item: 'c291f649aa5625b81322207177a41e2c4a08f09d', format: :html
    assert_tag(tag: 'meta', attributes: { 'name' => 'twitter:image' })
    assert_tag(tag: 'meta', attributes: { 'name' => 'twitter:card' })
    assert_tag(tag: 'meta', attributes: { 'name' => 'twitter:site' })
  end

  test "should not render Twitter metatags" do
    get :embed, project: 'google_spreadsheet', collection: 'test', format: :html
    assert_no_tag(tag: 'meta', attributes: { 'name' => 'twitter:image' })
    assert_no_tag(tag: 'meta', attributes: { 'name' => 'twitter:card' })
    assert_no_tag(tag: 'meta', attributes: { 'name' => 'twitter:site' })
  end

  test "should not have object if project is not supported" do
    get :embed, project: 'invalid', collection: 'invalid', format: :html
    assert_nil assigns(:object) 
    assert_response 404
  end

  test "should render png for items" do
    path = File.join(Rails.root, 'public', 'screenshots', 'google_spreadsheet', 'test', 'c291f649aa5625b81322207177a41e2c4a08f09d.png')
    assert !File.exists?(path)
    get :embed, project: 'google_spreadsheet', collection: 'test', item: 'c291f649aa5625b81322207177a41e2c4a08f09d', format: :png
    assert File.exists?(path)
  end

  test "should render png for collections" do
    path = File.join(Rails.root, 'public', 'screenshots', 'google_spreadsheet', 'test.png')
    assert !File.exists?(path)
    get :embed, project: 'google_spreadsheet', collection: 'test', format: :png
    assert File.exists?(path)
  end

  test "should render cached png" do
    Smartshot::Screenshot.expects(:new).never
    path = File.join(Rails.root, 'public', 'screenshots', 'google_spreadsheet', 'test', 'c291f649aa5625b81322207177a41e2c4a08f09d.png')
    FileUtils.mkdir_p(File.join(Rails.root, 'public', 'screenshots', 'google_spreadsheet', 'test'))
    FileUtils.touch(path)
    assert File.exists?(path)
    get :embed, project: 'google_spreadsheet', collection: 'test', item: 'c291f649aa5625b81322207177a41e2c4a08f09d', format: :png
  end

  test "should render png for Twitter" do
    id = '183773d82423893d9409faf05941bdbd63eb0b5c'
    generated = File.join(Rails.root, 'public', 'screenshots', 'google_spreadsheet', 'test', "#{id}.png")
    output = File.join(Rails.root, 'test', 'data', "#{id}.png")
    get :embed, project: 'google_spreadsheet', collection: 'test', item: id, format: :png
    FileUtils.cp(generated, "/tmp/#{id}.png")
    assert FileUtils.compare_file(generated, output)
  end

  test "should render png for Instagram" do
    id = 'c291f649aa5625b81322207177a41e2c4a08f09d'
    generated = File.join(Rails.root, 'public', 'screenshots', 'google_spreadsheet', 'test', "#{id}.png")
    output = File.join(Rails.root, 'test', 'data', "#{id}.png")
    get :embed, project: 'google_spreadsheet', collection: 'test', item: id, format: :png
    FileUtils.cp(generated, "/tmp/#{id}.png")
    assert FileUtils.compare_file(generated, output)
  end

  test "should render png with custom CSS" do
    id = '183773d82423893d9409faf05941bdbd63eb0b5c'
    FileUtils.rm_rf File.join(Rails.root, 'public', 'screenshots', 'google_spreadsheet', 'test', "#{id}.png")
    generated = File.join(Rails.root, 'public', 'screenshots', 'google_spreadsheet', 'test', "#{id}.png")
    assert !File.exists?(generated)
    output = File.join(Rails.root, 'test', 'data', "#{id}-custom-css.png")
    get :embed, project: 'google_spreadsheet', collection: 'test', item: id, format: :png, css: 'http://ca.ios.ba/files/meedan/ooew.css'
    FileUtils.cp(generated, "/tmp/#{id}-custom-css.png")
    assert FileUtils.compare_file(generated, output)
  end

  test "should render png with RTL text" do
    id = '6f975c79aa6644919907e3b107babf56803f57c7'
    FileUtils.rm_rf File.join(Rails.root, 'public', 'screenshots', 'google_spreadsheet', 'first', "#{id}.png")
    generated = File.join(Rails.root, 'public', 'screenshots', 'google_spreadsheet', 'first', "#{id}.png")
    assert !File.exists?(generated)
    output = File.join(Rails.root, 'test', 'data', "#{id}.png")
    get :embed, project: 'google_spreadsheet', collection: 'first', item: id, format: :png
    FileUtils.cp(generated, "/tmp/#{id}.png")
    assert FileUtils.compare_file(generated, output)
  end

  test "should set custom cache header" do
    get :embed, project: 'google_spreadsheet'
    assert_match /no-transform/, @response.headers['Cache-Control']
  end

  test "should return error if type is not supported" do
    BRIDGE_PROJECTS.stubs(:[]).returns({ type: 'invalid' })
    get :embed, project: 'google_spreadsheet'
    assert_response 404
  end

  test "should sanitize params" do
    get :embed, project: 'google_spreadsheet', collection: 'test/../..'
    assert_equal 'test', assigns(:collection)
  end

  test "should return error if item is not found" do
    get :embed, project: 'google_spreadsheet', collection: 'test', item: 'notfound'
    assert_response 404
  end

  test "should return error if collection is not found" do
    get :embed, project: 'google_spreadsheet', collection: 'teste'
    assert_response 404
  end
end
