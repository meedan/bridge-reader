require File.join(File.expand_path(File.dirname(__FILE__)), '..', 'test_helper')

class CheckApiTest < ActiveSupport::TestCase
  module Temp
  end

  def setup
    super
    WebMock.stub_request(:get, "http://checkapi/relay.json").to_return(:status => 200, :body => "")
    Temp.const_set :Client, mock
    Temp.const_set :Query, mock
    GraphQL::Client.stubs(:new).returns(Temp::Client)
    Temp::Client.stubs(:parse).returns('Query')
    @check = Sources::CheckApi.new('check-api', BRIDGE_PROJECTS['check-api'])
    @team_result = team_result
    @project_result = project_result
    @project_media_result = project_media_result
  end

  test "should return project slug as string representation" do
    assert_equal 'check-api', @check.to_s
  end

  test "should get a single translation" do
    Temp::Client.stubs(:query).with('Query', {:variables => {:ids => '2,1,', :annotation_type => 'translation'}}).returns(@project_media_result)
    stub_graphql_result(@project_media_result)

    t = @check.get_item('1', '2')
    assert_equal 'en', t[:source_lang]
    unstub_graphql_result(@project_media_result)
    Temp::Client.unstub(:query)
  end

  test "should not get nonexistent translation" do
    Temp::Client.stubs(:query).with('Query', {:variables => {:ids => '2,1,', :annotation_type => 'translation'}}).returns(@project_media_result)
    stub_graphql_result(@project_media_result)

    t = @check.get_item('1', '2')
    assert_nil t
    unstub_graphql_result(@project_media_result)
    Temp::Client.unstub(:query)
  end

  test "should get collection" do
    Temp::Client.stubs(:query).with('Query', {:variables => {:ids => '1,', :annotation_type => 'translation'}}).returns(@project_result)
    stub_graphql_result(@project_result)
    t = @check.get_collection('1')
    assert_equal 'en', t[0][:source_lang]
    unstub_graphql_result(@project_result)
    Temp::Client.unstub(:query)
  end

  test "should get project" do
    Temp::Client.stubs(:query).with('Query', {:variables => {:slug => 'chesssssssssssck-api'}}).returns(@team_result)
    stub_graphql_result(@team_result)

    assert_equal ['project'], @check.get_project.collect{ |c| c[:name] }
    unstub_graphql_result(@team_result)
    Temp::Client.unstub(:query)
  end

  private

  def team_result
    { data: { "team": { "dbid": 1, "description": "A brief description", "projects": { "edges": [ { "node": { "title": "project", "dbid": 1, "description": "project description" }}]}}}}
  end

  def project_result
    { data: { "project": { "dbid": 1, "title": "project", "description": "project description", "project_medias": { "edges": [{ "node": project_media_result[:data][:project_media] }]}}}}
  end

  def project_media_result
    { data: {"project_media": {"annotations_count": 1, "dbid": 2,"url": "","created_at": "2017-04-21 00:06:29 UTC","user": {"name": "John"},"language_code": "en","media": {"dbid": 2, "quote": "Hi", "url": ""}, "annotations": { "edges": [{"node": {"dbid": "119","annotated_id": "2","annotation_type": "translation","content":"[{\"id\":48,\"annotation_id\":119,\"field_name\":\"translation_text\",\"annotation_type\":\"translation\",\"field_type\":\"text\",\"value\":\"Teste\",\"created_at\":\"2017-04-28T22:47:15.568Z\",\"updated_at\":\"2017-04-28T22:47:15.568Z\"},{\"id\":49,\"annotation_id\":119,\"field_name\":\"translation_language\",\"annotation_type\":\"translation\",\"field_type\":\"language\",\"value\":\"pt\",\"created_at\":\"2017-04-28T22:47:15.585Z\",\"updated_at\":\"2017-04-28T22:47:15.585Z\"}]", "created_at": "2017-04-28 22:47:15 UTC", "annotator": {"name": "John Doe"}}}]}}}}
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

  def unstub_graphql_result(result)
    result.each_pair do |key, value|
      result.unstub(key)
      if value.is_a?(Hash)
        unstub_graphql_result(value)
      end
      if value.is_a?(Array)
        value.each do |e|
          unstub_graphql_result(e)
        end
      end
    end
  end

end
