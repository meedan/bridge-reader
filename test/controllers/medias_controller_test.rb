require File.join(File.expand_path(File.dirname(__FILE__)), '..', 'test_helper')

class MediasControllerTest < ActionController::TestCase

  def setup
    super
    @controller = MediasController.new
  end

  test "should allow iframe only for embed method" do
    get :embed
  end

end
