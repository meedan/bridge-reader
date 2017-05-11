require File.join(File.expand_path(File.dirname(__FILE__)), '..', 'test_helper')

class BridgeApiTest < ActiveSupport::TestCase
  def setup
    super
    @b = Sources::BridgeApi.new('bridge-api', BRIDGE_PROJECTS['bridge-api'])
  end

  test "should return project slug as string representation" do
    assert_equal 'bridge-api', @b.to_s
  end

  test "should get a single translation" do
    stub_request_single_translation
    t = @b.get_item('GreeceCrisis', '1')
    assert_equal 'en_US', t[:source_lang]
  end

  test "should not get nonexistent translation" do
    stub_request_nonexistent_translation
    t = @b.get_item('GreeceCrisis', 3)
    assert_nil t
  end

  test "should get many translations" do
    stub_request_many_translations
    t = @b.get_collection('GreeceCrisis')
    assert_equal 'en_US', t[0][:source_lang]
  end

  test "should return cached translations" do
    stub_request_many_translations
    Sources::BridgeApi.any_instance.expects(:format_params).returns('channel_uuid=GreeceCrisis').once
    @b.get_collection('GreeceCrisis')
    @b.get_collection('GreeceCrisis')
  end

  test "should not return cached translations" do
    stub_request_many_translations
    Sources::BridgeApi.any_instance.expects(:format_params).returns('channel_uuid=GreeceCrisis').twice
    @b.get_collection('GreeceCrisis')
    @b.get_collection('GreeceCrisis', nil, true)
  end

  test "should get project" do
    stub_request_project
    assert_equal ['fake2', 'fake3'], @b.get_project.collect{ |c| c['id'] }
  end

  test "should update cache for created translation" do
    stub_request_many_translations
    assert !File.exists?(@b.cache_path('bridge-api', 'GreeceCrisis', '1'))
    assert !File.exists?(@b.cache_path('bridge-api', 'GreeceCrisis', ''))
    assert !File.exists?(@b.cache_path('bridge-api', '', ''))
    @b.parse_notification('GreeceCrisis', '1', { 'condition' => 'created', 'translation' => JSON.parse(single_translation_object) })
    assert File.exists?(@b.cache_path('bridge-api', 'GreeceCrisis', '1'))
    assert File.exists?(@b.cache_path('bridge-api', 'GreeceCrisis', ''))
    assert File.exists?(@b.cache_path('bridge-api', '', ''))
  end

  test "should update cache for updated translation" do
    stub_request_many_translations
    @b.generate_cache(@b, 'bridge-api', 'GreeceCrisis', '1')
    @b.generate_cache(@b, 'bridge-api', 'GreeceCrisis', '')
    file1 = @b.cache_path('bridge-api', 'GreeceCrisis', '1')
    file2 = @b.cache_path('bridge-api', 'GreeceCrisis', '')
    file3 = @b.cache_path('bridge-api', '', '')
    assert File.exists?(file1)
    assert File.exists?(file2)
    assert !File.exists?(file3)
    time1 = File.mtime(file1)
    time2 = File.mtime(file2)
    @b.parse_notification('GreeceCrisis', '1', { 'condition' => 'updated', 'translation' => JSON.parse(single_translation_object) })
    assert File.mtime(file1) > time1
    assert File.mtime(file2) > time2
    assert File.exists?(file3)
  end

  test "should update cache for removed translation" do
    stub_request_many_translations
    @b.generate_cache(@b, 'bridge-api', 'GreeceCrisis', '1')
    @b.generate_cache(@b, 'bridge-api', 'GreeceCrisis', '')
    file1 = @b.cache_path('bridge-api', 'GreeceCrisis', '1')
    file2 = @b.cache_path('bridge-api', 'GreeceCrisis', '')
    file3 = @b.cache_path('bridge-api', '', '')
    assert File.exists?(file1)
    assert File.exists?(file2)
    assert !File.exists?(file3)
    time = File.mtime(file2)
    @b.parse_notification('GreeceCrisis', '1', { 'condition' => 'destroyed', 'translation' => JSON.parse(single_translation_object) })
    assert !File.exists?(file1)
    assert File.exists?(file2)
    assert File.exists?(file3)
    assert File.mtime(file2) > time
  end

  test "should create project" do
    project = File.join(Rails.root, 'config', 'projects', 'test', 'test.yml')
    assert !File.exists?(project)
    assert !BRIDGE_PROJECTS.has_key?('test')
    @b.parse_notification(nil, nil, { 'project' => { 'slug' => 'test' }, 'condition' => 'created', 'token' => 'access_token' })
    exists = File.exists?(project)
    FileUtils.rm(project)
    assert exists
    assert BRIDGE_PROJECTS.has_key?('test')
  end

  test "should not create project" do
    project = File.join(Rails.root, 'config', 'projects', 'test', 'test.yml')
    @b.parse_notification(nil, nil, { 'project' => { 'slug' => 'test' } })
    assert !File.exists?(project)
  end

  test "should update project cache" do
    stub_request_project
    @b.generate_cache(@b, 'bridge-api', '', '')
    file = @b.cache_path('bridge-api', '', '')
    assert File.exists?(file)
    time = File.mtime(file)
    @b.parse_notification('', '', { 'condition' => 'updated', 'project' => { 'id' => 1 } })
    assert File.exists?(file)
    assert File.mtime(file) > time
  end

  test "should limit collection items" do
    stub_request_many_translations
    b = Sources::BridgeApi.new('bridge-api', BRIDGE_PROJECTS['bridge-api'].merge({ 'max_items_per_column' => 1 }))
    t = b.get_collection('GreeceCrisis')
    assert_equal 1, t.size
    t = @b.get_collection('GreeceCrisis')
    assert_equal 2, t.size
  end

  protected

  def single_translation_object
    '{"id":1,"lang":"pt_BR","published":1438111529,"author":{"id":"1666372892","name":"Marcelo Souza","link":"https://twitter.com/intent/user?user_id=1666372892"},"text":"#CriseGrega - Morte ou Renascimento da União Européia?","rating":{"myRating":null,"greatCount":0},"embed_url":"http://bridgembed/medias/embed/eye-on-greece/GreeceCrisis/1","source":{"lang":"en_US","text":"#GreeceCrisis – Death or Rebirth of the EU? http://t.co/3gJl6dDxZf\nSee more by James Galbraith on Project Syndicate http://t.co/U6S7hyaOTM","published":1438095303,"link":"https://twitter.com/ProSyn/status/626088494448795649"},"comments":[{"id":1,"text":"A comment","published":1438111529,"author":{"id":"1666372892","name":"Marcelo Souza","link":"https://twitter.com/intent/user?user_id=1666372892"}}]}'
  end

  private

  def stub_request_single_translation
    body = "{\"data\":#{self.single_translation_object}}"
    WebMock.stub_request(:get, 'http://bridge.api/api/translations/1').to_return(body: body, status: 200)
  end

  def stub_request_nonexistent_translation
    WebMock.stub_request(:get, 'http://bridge.api/api/translations/3').to_return(body: '{"type":"error","data":{"message":"Id not found","code":3}}', status: 404)
  end

  def stub_request_many_translations
    body = "{\"data\":[#{self.single_translation_object},#{self.single_translation_object}]}"
    WebMock.stub_request(:get, 'http://bridge.api/api/translations?channel_uuid=GreeceCrisis').to_return(body: body, status: 200)
  end

  def stub_request_project
    body = '{"type":"channels","data":[{"id":"fake","name":"Fake User Author","topic":4,"category":"Other","followed":false,"translations_count":0},{"id":"fake2","name":"Fake User Mention","topic":4,"category":"Other","followed":false,"translations_count":2},{"id":"fake3","name":"Fake List","topic":4,"category":"Other","followed":false,"translations_count":3}]}'
    WebMock.stub_request(:get, 'http://bridge.api/api/projects/bridge-api/channels').to_return(body: body, status: 200)
  end
end
