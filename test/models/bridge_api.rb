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
    assert_equal ['fake', 'fake2', 'fake3'], @b.get_project
  end

  private

  def stub_request_single_translation
    body = '{"data":{"id":1,"lang":"pt_BR","published":1438111529,"author":{"id":"1666372892","name":"Marcelo Souza","link":"https://twitter.com/intent/user?user_id=1666372892"},"text":"#CriseGrega - Morte ou Renascimento da União Européia?","rating":{"myRating":null,"greatCount":0},"embed_url":"http://bridgembed/medias/embed/eye-on-greece/GreeceCrisis/1","source":{"lang":"en_US","text":"#GreeceCrisis – Death or Rebirth of the EU? http://t.co/3gJl6dDxZf\nSee more by James Galbraith on Project Syndicate http://t.co/U6S7hyaOTM","published":1438095303,"link":"https://twitter.com/ProSyn/status/626088494448795649"}}}'
    WebMock.stub_request(:get, 'http://bridge.api/api/translations/1').to_return(body: body, status: 200)
  end

  def stub_request_nonexistent_translation
    WebMock.stub_request(:get, 'http://bridge.api/api/translations/3').to_return(body: '{"type":"error","data":{"message":"Id not found","code":3}}', status: 404)
  end

  def stub_request_many_translations
    body = '{"data":[{"id":1,"lang":"pt_BR","published":1438111529,"author":{"id":"1666372892","name":"Marcelo Souza","link":"https://twitter.com/intent/user?user_id=1666372892"},"text":"#CriseGrega - Morte ou Renascimento da União Européia?","rating":{"myRating":null,"greatCount":0},"embed_url":"http://bridgembed/medias/embed/eye-on-greece/GreeceCrisis/1","source":{"lang":"en_US","text":"#GreeceCrisis – Death or Rebirth of the EU? http://t.co/3gJl6dDxZf\nSee more by James Galbraith on Project Syndicate http://t.co/U6S7hyaOTM","published":1438095303,"link":"https://twitter.com/ProSyn/status/626088494448795649"}}]}'
    WebMock.stub_request(:get, 'http://bridge.api/api/translations?channel_uuid=GreeceCrisis').to_return(body: body, status: 200)
  end

  def stub_request_project
    body = '{"type":"channels","data":[{"id":"fake","name":"Fake User Author","topic":4,"category":"Other","followed":false},{"id":"fake2","name":"Fake User Mention","topic":4,"category":"Other","followed":false},{"id":"fake3","name":"Fake List","topic":4,"category":"Other","followed":false}]}'
    WebMock.stub_request(:get, 'http://bridge.api/api/projects/bridge-api/channels').to_return(body: body, status: 200)
  end
end
