require File.join(File.expand_path(File.dirname(__FILE__)), '..', 'test_helper')

class MediasIntegrationTest < ActionDispatch::IntegrationTest

  test "should redirect to embed method" do
    assert_recognizes({ controller: 'medias', action: 'embed', milestone: 'test' }, { path: 'medias/embed/test', method: :get })
  end

end
