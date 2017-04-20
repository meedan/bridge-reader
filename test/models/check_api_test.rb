require File.join(File.expand_path(File.dirname(__FILE__)), '..', 'test_helper')

class CheckApiTest < ActiveSupport::TestCase
  def setup
    super
    @check = Sources::CheckApi.new('check-api', BRIDGE_PROJECTS['check-team'])
  end

  test "should return project slug as string representation" do
    assert_equal 'check-api', @check.to_s
  end

  test "should get a single translation" do
    stub_request_project_media
    t = @check.get_item('1', '2')
    assert_equal 'en', t[:source_lang]
  end

  test "should not get nonexistent translation" do
    stub_request_project_media
    t = @check.get_item('1', '2')
    assert_nil t
  end

  test "should get many translations" do
    stub_request_project
    t = @check.get_collection('1')
    assert_equal 'en', t[0][:source_lang]
  end

  test "should get project" do
    stub_request_team
    assert_equal ['project'], @check.get_project.collect{ |c| c['id'] }
  end

  private

  def stub_request_team
    result = { "team": { "dbid": 1, "description": "A brief description", "projects": { "edges": [ { "node": { "title": "project", "dbid": 1, "description": "project description" }}]}}}
    Client.stubs(:query).returns(result)
  end

  def stub_request_project
    result = { "project": { "dbid": 1, "title": "project", "description": "project description", "project_medias": { "edges": [{ "node": { "dbid": 1, "url": null, "created_at": "2017-04-21 00:06:47 UTC", "user": { "name": "John" }, "language": null, "media": { "dbid": 1, "quote": "Hello" }}}, {"node": {"dbid": 2, "url": null, "created_at": "2017-04-21 00:06:29 UTC", "user": { "name": "John" }, "language": null, "media": { "dbid": 2, "quote": "Hi"}}}]}}}
    Client.stubs(:query).returns(result)
  end

  def stub_request_project_media
    result = {"project_media": {"dbid": 2,"url": null,"created_at": "2017-04-21 00:06:29 UTC","user": {"name": "John"},"language": null,"media": {"dbid": 2, "quote": "Hi"}}}
  end
end
