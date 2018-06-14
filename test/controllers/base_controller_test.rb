require File.join(File.expand_path(File.dirname(__FILE__)), '..', 'test_helper')

class BaseControllerTest < ActionController::TestCase
  def setup
    super
    @controller = MediasController.new
  end

  test "should render png for items" do
    puts 'Running screenshot test...'
    path = File.join(Rails.root, 'public', 'screenshots', 'google_spreadsheet', 'watchbot', 'cac1af59cc9b410752fcbe3810b36d30ed8e049d.png')
    assert !File.exists?(path)
    get :embed, project: 'google_spreadsheet', collection: 'watchbot', item: 'cac1af59cc9b410752fcbe3810b36d30ed8e049d', format: :png
    assert File.exists?(path)
  end

  test "should not render png for collections" do
    puts 'Running screenshot test...'
    path = File.join(Rails.root, 'public', 'screenshots', 'google_spreadsheet', 'test2.png')
    assert !File.exists?(path)
    get :embed, project: 'google_spreadsheet', collection: 'test2', format: :png
    assert !File.exists?(path)
  end

  test "should render cached png" do
    path = File.join(Rails.root, 'public', 'screenshots', 'google_spreadsheet', 'first', '6f975c79aa6644919907e3b107babf56803f57c7.png')
    FileUtils.mkdir_p(File.join(Rails.root, 'public', 'screenshots', 'google_spreadsheet', 'first'))
    FileUtils.touch(path)
    assert File.exists?(path)
    get :embed, project: 'google_spreadsheet', collection: 'first', item: '6f975c79aa6644919907e3b107babf56803f57c7', format: :png
  end

  test "should render png for Twitter" do
    puts 'Running screenshot test...'
    id = '09ba77abe84d84fb6531255b458980cd4af9ea9a'
    generated = File.join(Rails.root, 'public', 'screenshots', 'google_spreadsheet', 'watchbot', "#{id}.png")
    output = File.join(Rails.root, 'test', 'data', "#{id}.png")
    get :embed, project: 'google_spreadsheet', collection: 'watchbot', item: id, format: :png
    FileUtils.cp(generated, "/tmp/#{id}.png")
    assert_same_image generated, output
  end

  test "should render png for Instagram" do
    puts 'Running screenshot test...'
    id = 'cac1af59cc9b410752fcbe3810b36d30ed8e049d'
    generated = File.join(Rails.root, 'public', 'screenshots', 'google_spreadsheet', 'watchbot', "#{id}.png")
    output = File.join(Rails.root, 'test', 'data', "#{id}.png")
    get :embed, project: 'google_spreadsheet', collection: 'watchbot', item: id, format: :png
    assert_same_image generated, output
  end

  test "should not render specific png with custom CSS" do
    puts 'Running screenshot test...'
    project, collection, id = 'google_spreadsheet', 'test', '183773d82423893d9409faf05941bdbd63eb0b5c'
    css = 'http://ca.ios.ba/files/meedan/ooew.css'
    css_hash = Digest::MD5.hexdigest(css.parameterize)
    FileUtils.rm_rf File.join(Rails.root, 'public', 'screenshots', project, collection, "#{id}-#{css_hash}.png")
    generated = File.join(Rails.root, 'public', 'screenshots', project, collection, "#{id}-#{css_hash}.png")
    url = [BRIDGE_CONFIG['bridgembed_host'], 'medias', 'embed', project, URI.encode(collection), id].join('/') + '?&template=screenshot' + "#css=#{css}"
    PenderClient::Request.delete_medias(BRIDGE_CONFIG['pender_base_url'], {url: url}, BRIDGE_CONFIG['pender_token'])
    assert !File.exists?(generated)
    output = File.join(Rails.root, 'test', 'data', "#{id}-custom-css.png")
    get :embed, project: project, collection: collection, item: id, format: :png, css: css
    assert_not_equal generated, output
  end

  test "should render png with RTL text" do
    puts 'Running screenshot test...'
    id = '6f975c79aa6644919907e3b107babf56803f57c7'
    FileUtils.rm_rf File.join(Rails.root, 'public', 'screenshots', 'google_spreadsheet', 'first', "#{id}.png")
    generated = File.join(Rails.root, 'public', 'screenshots', 'google_spreadsheet', 'first', "#{id}.png")
    assert !File.exists?(generated)
    output = File.join(Rails.root, 'test', 'data', "#{id}.png")
    get :embed, project: 'google_spreadsheet', collection: 'first', item: id, format: :png
    assert_same_image generated, output
  end

  test "should render png with ratio 2:1 if width / height < 2" do
    puts 'Running screenshot test...'
    project, collection, id = 'google_spreadsheet', 'test', '183773d82423893d9409faf05941bdbd63eb0b5c'
    FileUtils.rm_rf File.join(Rails.root, 'public', 'screenshots', project, collection, "#{id}.png")
    generated = File.join(Rails.root, 'public', 'screenshots', project, collection, "#{id}.png")
    url = [BRIDGE_CONFIG['bridgembed_host'], 'medias', 'embed', project, URI.encode(collection), id].join('/') + '?&template=screenshot'
    PenderClient::Request.delete_medias(BRIDGE_CONFIG['pender_base_url'], {url: url}, BRIDGE_CONFIG['pender_token'])
    assert !File.exists?(generated)
    output = File.join(Rails.root, 'test', 'data', 'ratiolt2.png')
    get :embed, project: project, collection: collection, item: id, format: :png
    assert_same_image generated, output
  end

  test "should render png with ratio 2:1 if width / height > 2" do
    puts 'Running screenshot test...'
    id = '09ba77abe84d84fb6531255b458980cd4af9ea9a'
    generated = File.join(Rails.root, 'public', 'screenshots', 'google_spreadsheet', 'watchbot', "#{id}.png")
    output = File.join(Rails.root, 'test', 'data', 'ratiogt2.png')
    get :embed, project: 'google_spreadsheet', collection: 'watchbot', item: id, format: :png
    FileUtils.cp(generated, '/tmp/ratiogt2.png')
    assert_same_image generated, output
  end

  test "should render png for Instagram video" do
    puts 'Running screenshot test...'
    id = 'cac1af59cc9b410752fcbe3810b36d30ed8e049d'
    assert_nothing_raised do
      get :embed, project: 'google_spreadsheet', collection: 'watchbot', item: id, format: :png
    end
  end

  test "should render png for Twitter 2" do
    puts 'Running screenshot test...'
    id = '09ba77abe84d84fb6531255b458980cd4af9ea9a'
    assert_nothing_raised do
      get :embed, project: 'google_spreadsheet', collection: 'watchbot', item: id, format: :png
    end
  end
end
