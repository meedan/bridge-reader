require File.join(File.expand_path(File.dirname(__FILE__)), '..', 'test_helper')

class MediasIntegrationTest < ActionDispatch::IntegrationTest
  test "should redirect to embed method" do
    assert_recognizes({ controller: 'medias', action: 'embed', type: 'milestone', id: 'test' }, { path: 'medias/embed/milestone/test', method: :get })
  end

  test "should redirect to single embed method" do
    assert_recognizes({ controller: 'medias', action: 'embed', type: 'link', id: '123456' }, { path: 'medias/embed/link/123456', method: :get })
  end

  test "should lazy-load Instagram image" do
    with_testing_page '<script type="text/javascript" src="/medias/embed/milestone/test.js"></script>' do
      within_frame 0 do
        within_frame 1 do
          assert page.find('img.art-bd-img').visible? # Assert that Instagram image is visible
          assert !page.has_css?('link.bridgembed-custom-css', visible: false)
        end
      end
    end
  end

  test "should have custom css" do
    with_testing_style 'body { background: red !important; }' do
      visit '/'
      url = current_url + 'medias/embed/milestone/test.js'
      with_testing_page ('<script type="text/javascript" src="' + url + '" data-custom-css="/test/test.css"></script>') do
        within_frame 0 do
          assert page.has_css?('link.bridgembed-custom-css', visible: false)
          color = page.evaluate_script('getComputedStyle(document.getElementsByTagName("BODY")[0]).getPropertyValue("background-color")')
          assert_equal 'rgb(255, 0, 0)', color
        end
      end
    end
  end
end
