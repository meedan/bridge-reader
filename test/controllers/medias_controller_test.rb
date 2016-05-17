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
    PageValidations::HTMLValidation.show_warnings = false
    h = PageValidations::HTMLValidation.new
    clear_cache
    get :embed, project: 'google_spreadsheet', collection: 'test'
    file = File.join(Rails.root, 'public', 'cache', 'google_spreadsheet', 'test.html')
    v = h.validation(File.read(file), BRIDGE_CONFIG['bridgembed_host'])
    assert v.valid?, v.exceptions
  end

  test "should render JavaScript" do
    get :embed, project: 'google_spreadsheet', collection: 'test', format: :js
    assert_equal 'http://test.host/medias/embed/google_spreadsheet/test', assigns(:url)
    assert_equal 'http://test.host/medias/embed/google_spreadsheet/test.js', assigns(:caller)
    assert_equal '/medias/embed/google_spreadsheet/test.js', assigns(:caller_path)
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
    assert_equal MiniMagick::Image.new(generated).signature, MiniMagick::Image.new(output).signature
  end

  test "should render png for Instagram" do
    id = 'c291f649aa5625b81322207177a41e2c4a08f09d'
    generated = File.join(Rails.root, 'public', 'screenshots', 'google_spreadsheet', 'test', "#{id}.png")
    output = File.join(Rails.root, 'test', 'data', "#{id}.png")
    get :embed, project: 'google_spreadsheet', collection: 'test', item: id, format: :png
    FileUtils.cp(generated, "/tmp/#{id}.png")
    assert_equal MiniMagick::Image.new(generated).signature, MiniMagick::Image.new(output).signature
  end

  test "should render png with custom CSS" do
    id = '183773d82423893d9409faf05941bdbd63eb0b5c'
    FileUtils.rm_rf File.join(Rails.root, 'public', 'screenshots', 'google_spreadsheet', 'test', "#{id}.png")
    generated = File.join(Rails.root, 'public', 'screenshots', 'google_spreadsheet', 'test', "#{id}.png")
    assert !File.exists?(generated)
    output = File.join(Rails.root, 'test', 'data', "#{id}-custom-css.png")
    get :embed, project: 'google_spreadsheet', collection: 'test', item: id, format: :png, css: 'http://ca.ios.ba/files/meedan/ooew.css'
    FileUtils.cp(generated, "/tmp/#{id}-custom-css.png")
    assert_equal MiniMagick::Image.new(generated).signature, MiniMagick::Image.new(output).signature
  end

  test "should render png with RTL text" do
    id = '6f975c79aa6644919907e3b107babf56803f57c7'
    FileUtils.rm_rf File.join(Rails.root, 'public', 'screenshots', 'google_spreadsheet', 'first', "#{id}.png")
    generated = File.join(Rails.root, 'public', 'screenshots', 'google_spreadsheet', 'first', "#{id}.png")
    assert !File.exists?(generated)
    output = File.join(Rails.root, 'test', 'data', "#{id}.png")
    get :embed, project: 'google_spreadsheet', collection: 'first', item: id, format: :png
    FileUtils.cp(generated, "/tmp/#{id}.png")
    assert_equal MiniMagick::Image.new(generated).signature, MiniMagick::Image.new(output).signature
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

  test "should sanitize Arabic params" do
    get :embed, project: 'google_spreadsheet', collection: 'عوده_الوايت_نايتس'
    assert_equal 'عوده_الوايت_نايتس', assigns(:collection)
  end

  test "should return error for screenshot that doesn't exist" do
    get :embed, project: 'google_spreadsheet', collection: 'teste', format: :png
    assert_response 404
  end

  test "should remove parameters from caller JavaScript" do
    get :embed, project: 'google_spreadsheet', collection: 'test', format: :js, t: 123456
    assert_equal 'http://test.host/medias/embed/google_spreadsheet/test', assigns(:url)
    assert_equal 'http://test.host/medias/embed/google_spreadsheet/test.js', assigns(:caller)
    assert_equal '/medias/embed/google_spreadsheet/test.js', assigns(:caller_path)
  end

  test "should render png with ratio 2:1 if width / height < 2" do
    id = '183773d82423893d9409faf05941bdbd63eb0b5c'
    generated = File.join(Rails.root, 'public', 'screenshots', 'google_spreadsheet', 'test', "#{id}.png")
    output = File.join(Rails.root, 'test', 'data', 'ratiolt2.png')
    get :embed, project: 'google_spreadsheet', collection: 'test', item: id, format: :png
    FileUtils.cp(generated, '/tmp/ratiolt2.png')
    assert_equal MiniMagick::Image.new(generated).signature, MiniMagick::Image.new(output).signature
  end

  test "should render png with ratio 2:1 if width / height > 2" do
    id = 'c291f649aa5625b81322207177a41e2c4a08f09d'
    generated = File.join(Rails.root, 'public', 'screenshots', 'google_spreadsheet', 'test', "#{id}.png")
    output = File.join(Rails.root, 'test', 'data', 'ratiogt2.png')
    get :embed, project: 'google_spreadsheet', collection: 'test', item: id, format: :png
    FileUtils.cp(generated, '/tmp/ratiogt2.png')
    assert_equal MiniMagick::Image.new(generated).signature, MiniMagick::Image.new(output).signature
  end

  test "should render png for Instagram video" do
    id = 'cac1af59cc9b410752fcbe3810b36d30ed8e049d'
    assert_nothing_raised do
      get :embed, project: 'google_spreadsheet', collection: 'watchbot', item: id, format: :png
    end
  end

  test "should render png for Twitter 2" do
    id = '09ba77abe84d84fb6531255b458980cd4af9ea9a'
    assert_nothing_raised do
      get :embed, project: 'google_spreadsheet', collection: 'watchbot', item: id, format: :png
    end
  end

  test "should have Facebook metatags for project" do
    get :embed, project: 'google_spreadsheet', format: :html
    assert_tag(tag: 'meta', attributes: { 'property' => 'og:title', 'content' => 'Translations of Google Spreadsheet' })
    assert_tag(tag: 'meta', attributes: { 'property' => 'og:image', 'content' => /bridge-logo\.png/ })
    assert_tag(tag: 'meta', attributes: { 'property' => 'og:description' })
  end

  test "should have Facebook metatags for collection" do
    get :embed, project: 'google_spreadsheet', collection: 'test', format: :html
    assert_tag(tag: 'meta', attributes: { 'property' => 'og:title', 'content' => 'Translations of Google Spreadsheet / Test' })
    assert_tag(tag: 'meta', attributes: { 'property' => 'og:image', 'content' => /bridge-logo\.png/ })
    assert_tag(tag: 'meta', attributes: { 'property' => 'og:description', 'content' => 'Translations of Google Spreadsheet / Test' })
  end

  test "should have Facebook metatags for item" do
    id = 'cac1af59cc9b410752fcbe3810b36d30ed8e049d'
    get :embed, project: 'google_spreadsheet', collection: 'watchbot', item: id, format: :html
    assert_tag(tag: 'meta', attributes: { 'property' => 'og:title', 'content' => 'Translation of @ahmadabou: Vídeo do Instagram' })
    assert_tag(tag: 'meta', attributes: { 'property' => 'og:image', 'content' => /#{id}\.png/ })
    assert_tag(tag: 'meta', attributes: { 'property' => 'og:description', 'content' => 'Translation of @ahmadabou: Vídeo do Instagram' })
  end

  test "should render HTML with template" do
    id = 'cac1af59cc9b410752fcbe3810b36d30ed8e049d'
    get :embed, project: 'google_spreadsheet', collection: 'watchbot', item: id, format: :html, template: 'screenshot'
    assert_not_nil assigns(:entries)
  end

  test "should fallback to default when template is not present" do
    id = 'cac1af59cc9b410752fcbe3810b36d30ed8e049d'
    get :embed, project: 'google_spreadsheet', collection: 'watchbot', item: id, format: :html, template: 'invalid'
    assert_nil assigns(:entries)
  end

  test "should not raise screenshot exception if agent is a Slack bot" do
    @request.env['HTTP_USER_AGENT'] = 'Slack-ImgProxy 1.127'
    MediasController.any_instance.stubs(:generate_screenshot).raises(Exception)
    assert_nothing_raised do
      get :embed, project: 'google_spreadsheet', collection: 'test', item: 'c291f649aa5625b81322207177a41e2c4a08f09d', format: :png
      assert_response 400
    end
    MediasController.unstub(:generate_screenshot)
  end

  test "should not raise screenshot exception if agent is a Twitter bot" do
    @request.env['HTTP_USER_AGENT'] = 'Twitterbot'
    MediasController.any_instance.stubs(:generate_screenshot).raises(Exception)
    assert_nothing_raised do
      get :embed, project: 'google_spreadsheet', collection: 'test', item: 'c291f649aa5625b81322207177a41e2c4a08f09d', format: :png
      assert_response 400
    end
    MediasController.unstub(:generate_screenshot)
  end

  test "should not raise screenshot exception if agent is Yahoo! Slurp" do
    @request.env['HTTP_USER_AGENT'] = 'Mozilla 5.0 (Yahoo! Slurp)'
    MediasController.any_instance.stubs(:generate_screenshot).raises(Exception)
    assert_nothing_raised do
      get :embed, project: 'google_spreadsheet', collection: 'test', item: 'c291f649aa5625b81322207177a41e2c4a08f09d', format: :png
      assert_response 400
    end
    MediasController.unstub(:generate_screenshot)
  end

  test "should raise screenshot exception if agent is not a bot" do
    @request.env['HTTP_USER_AGENT'] = 'Google Chrome'
    MediasController.any_instance.stubs(:generate_screenshot).raises(Exception)
    assert_raises RuntimeError do
      get :embed, project: 'google_spreadsheet', collection: 'test', item: 'c291f649aa5625b81322207177a41e2c4a08f09d', format: :png
    end
    MediasController.unstub(:generate_screenshot)
  end

  test "should return 404 for screenshot of unexistent item" do
    get :embed, project: 'google_spreadsheet', collection: 'watchbot', item: 'unexistent', format: :html, template: 'screenshot'
    assert_response 404
  end
end
