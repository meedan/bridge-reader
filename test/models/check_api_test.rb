require File.join(File.expand_path(File.dirname(__FILE__)), '..', 'test_helper')

class CheckApiTest < ActiveSupport::TestCase
  module Temp
  end

  def setup
    super
    WebMock.stub_request(:get, "#{BRIDGE_CONFIG['check_api_url']}/relay.json").to_return(:status => 200, :body => "")
    Temp.const_set :Client, mock('client')
    Temp.const_set :Query, mock('query')

    Temp::Client.stubs(:parse).returns('Query')
    GraphQL::Client.stubs(:new).returns(Temp::Client)

    reload_classes

    @check = Sources::CheckApi.new('check-api', BRIDGE_PROJECTS['check-api'])
    @team_result = team_result
    @project_result = project_result
    @project_media_result = project_media_result
    @project_media_without_translation_result = project_media_without_translation_result
  end

  test "should send token as header" do
    token = BRIDGE_CONFIG['check_api_token']
    assert_equal token, Check::HTTPAdapter.headers('context')['X-Check-Token']
  end

  test "should return project slug as string representation" do
    assert_equal 'check-api', @check.to_s
  end

  test "should get a single translation" do
    Temp::Client.stubs(:query).with('Query', {:variables => {:ids => '2,1,', :annotation_types => 'translation,translation_status'}}).returns(@project_media_result)
    stub_graphql_result(@project_media_result)

    t = @check.get_item('1', '2')
    assert_equal 'en', t[:source_lang]
  end

  test "should not return check item with nonexistent translation" do
    Temp::Client.stubs(:query).with('Query', {:variables => {:ids => '3,1,', :annotation_types => 'translation,translation_status'}}).returns(@project_media_without_translation_result)
    stub_graphql_result(@project_media_without_translation_result)

    t = @check.get_item('1', '3')
    assert_nil t
    Temp::Client.unstub(:query)
  end

  test "should get collection" do
    Temp::Client.stubs(:query).with('Query', {:variables => {:ids => '1,', :annotation_types => 'translation,translation_status'}}).returns(@project_result)
    stub_graphql_result(@project_result)

    t = @check.get_collection('1')
    assert_equal 'en', t[0][:source_lang]
  end

  test "should get project" do
    Temp::Client.stubs(:query).with('Query', {:variables => {:slug => 'check-api'}}).returns(@team_result)
    stub_graphql_result(@team_result)

    assert_equal ['project'], @check.get_project.collect{ |c| c[:name] }
  end

  private

  def reload_classes
    Object.send(:remove_const, :Check) if Module.const_defined?(:Check)
    load File.join(Rails.root, 'lib', 'check_api_client.rb')
    Sources.send(:remove_const, :CheckApi) if Module.const_defined?(:CheckApi)
    load File.join(Rails.root, 'app', 'sources', 'check_api.rb')
  end

  def team_result
    { data: { "team": { "dbid": 1, "description": "A brief description", "projects": { "edges": [ { "node": { "title": "project", "dbid": 1, "description": "project description" }}]}}}}
  end

  def project_result
    { data: { "project": { "dbid": 1, "title": "project", "description": "project description", "project_medias": { "edges": [{ "node": project_media_result[:data][:project_media] }]}}}}
  end

  def project_media_result
    { data: {"project_media": {"annotations_count": 1, "dbid": 2,"url": "","created_at": "2017-04-21 00:06:29 UTC","user": {"name": "John"},"language_code": "en","media": {"dbid": 2, "quote": "Hi", "url": ""}, "annotations": { "edges": [{"node": {"dbid": "119","annotated_id": "2","annotation_type": "translation","content":"[{\"id\":48,\"annotation_id\":119,\"field_name\":\"translation_text\",\"annotation_type\":\"translation\",\"field_type\":\"text\",\"value\":\"Teste\",\"created_at\":\"2017-04-28T22:47:15.568Z\",\"updated_at\":\"2017-04-28T22:47:15.568Z\"},{\"id\":49,\"annotation_id\":119,\"field_name\":\"translation_language\",\"annotation_type\":\"translation\",\"field_type\":\"language\",\"value\":\"pt\",\"created_at\":\"2017-04-28T22:47:15.585Z\",\"updated_at\":\"2017-04-28T22:47:15.585Z\"}, {\"id\":50,\"annotation_id\":119,\"field_name\":\"translation_note\",\"annotation_type\":\"translation\",\"field_type\":\"text\",\"value\":\"Good translation\",\"created_at\":\"2017-05-08T16:05:53.762Z\",\"updated_at\":\"2017-05-08T16:05:53.762Z\",\"formatted_value\":\"Good translation\"}]", "created_at": "2017-04-28 22:47:15 UTC", "annotator": {"name": "John Doe"}}}, { "node": { "dbid": "180", "annotated_id": "2", "annotation_type": "translation_status", "content": "[{\"id\":102,\"annotation_id\":180,\"field_name\":\"translation_status_status\",\"annotation_type\":\"translation_status\",\"field_type\":\"select\",\"value\":\"ready\",\"created_at\":\"2017-05-09T13:31:25.043Z\",\"updated_at\":\"2017-05-09T13:31:25.043Z\",\"formatted_value\":\"Ready\"},{\"id\":103,\"annotation_id\":180,\"field_name\":\"translation_status_approver\",\"annotation_type\":\"translation_status\",\"field_type\":\"json\",\"value\":\"{\\\"name\\\":\\\"John\\\",\\\"url\\\":null}\",\"created_at\":\"2017-05-09T13:31:25.075Z\",\"updated_at\":\"2017-05-09T13:31:25.075Z\",\"formatted_value\":\"{\\\"name\\\":\\\"John\\\",\\\"url\\\":null}\"}]", "created_at": "2017-05-09 13:31:25 UTC",  "annotator": { "name": "Mary" }}}]}}}}
  end

  def project_media_without_translation_result
    { data: {"project_media": {"dbid": 3, "url": "", "created_at": "2017-04-21 14:17:58 UTC", "user": {"name": "John"}, "language_code": "en", "annotations_count": 0, "annotations": { "edges": [] }, "media": { "dbid": 39, "quote": "Hello", "url": "" }}}}
  end

  def stub_graphql_result(result)
    result.each_pair do |key, value|
      result.stubs(key).returns(value)
      if value.is_a?(Hash)
        stub_graphql_result(value)
      end
      if value.is_a?(Array)
        value.each do |e|
          stub_graphql_result(e)
        end
      end
    end
  end
end
