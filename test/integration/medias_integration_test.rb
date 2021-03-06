require File.join(File.expand_path(File.dirname(__FILE__)), '..', 'test_helper')

class MediasIntegrationTest < ActionDispatch::IntegrationTest
  test "should have custom css" do
    with_testing_style 'body { background: red !important; }' do
      url = BRIDGE_CONFIG['bridgembed_host_private'] + '/medias/embed/google_spreadsheet/test.js'
      with_testing_page ('<script type="text/javascript" src="' + url + '" data-custom-css="/test/test.css"></script>') do
        within_frame 0 do
          assert page.has_css?('link.bridgembed-custom-css', visible: false)
          color = page.evaluate_script('getComputedStyle(document.getElementsByTagName("BODY")[0]).getPropertyValue("background-color")')
          assert_equal 'rgb(255, 0, 0)', color
        end
      end
    end
  end

  test "should open share menu" do
    js do
      visit '/medias/embed/google_spreadsheet/test'
      # Capybara::Screenshot.screenshot_and_open_image
      assert !page.has_text?('SHARE ON TWITTER')
      assert !page.has_text?('SHARE ON FACEBOOK')
      page.first(:link, 'Share').click
      sleep 2.seconds
      assert page.has_text?('SHARE ON TWITTER')
      assert page.has_text?('SHARE ON FACEBOOK')
    end
  end

  test "should share on Twitter" do
    js do
      visit '/medias/embed/google_spreadsheet/test'
      page.first(:link, 'Share').click
      page.first(:link, 'Share on Twitter').click
      twitter = page.driver.window_handles.last
      page.within_window twitter do
        assert_equal 'twitter.com', URI.parse(current_url).host
      end
    end
  end

  test "should share on Facebook" do
    js do
      visit '/medias/embed/google_spreadsheet/test'
      page.first(:link, 'Share').click
      page.first(:link, 'Share on Facebook').click
      fb = page.driver.window_handles.last
      page.within_window fb do
        assert_equal 'www.facebook.com', URI.parse(current_url).host
      end
    end
  end

  test "should display RTL text" do
    js do
      visit '/medias/embed/google_spreadsheet/first/6f975c79aa6644919907e3b107babf56803f57c7.html'
      assert_equal 'rtl', page.evaluate_script('getComputedStyle(document.getElementsByTagName("P")[0]).getPropertyValue("direction")')
    end
  end

  test "should display LTR text" do
    js do
      visit '/medias/embed/google_spreadsheet/test/c291f649aa5625b81322207177a41e2c4a08f09d.html'
      assert_equal 'ltr', page.evaluate_script('getComputedStyle(document.getElementsByTagName("P")[0]).getPropertyValue("direction")')
    end
  end

  test "should embed a project" do
    assert_recognizes({ controller: 'medias', action: 'embed', project: 'test-project' }, { path: 'medias/embed/test-project', method: :get })
  end

  test "should embed a collection" do
    assert_recognizes({ controller: 'medias', action: 'embed', project: 'test-project', collection: 'test-collection' }, { path: 'medias/embed/test-project/test-collection', method: :get })
  end

  test "should embed a single item" do
    assert_recognizes({ controller: 'medias', action: 'embed', project: 'test-project', collection: 'test-collection', item: 'test-item' }, { path: 'medias/embed/test-project/test-collection/test-item', method: :get })
  end

  test "should validate project format" do
    assert_raises(ActionController::RoutingError) do
      get 'medias/embed/project%20that$is@invalid'
    end
    assert_nothing_raised do
      get '/medias/embed/project_THAT-is_v4l1d'
    end
  end

  test "should validate collect format" do
    assert_raises(ActionController::RoutingError) do
      get 'medias/embed/project/collection%20that$is@invalid'
    end
    assert_nothing_raised do
      get '/medias/embed/project/collection_THAT-is_v4l1d'
    end
  end

  test "should validate item format" do
    assert_raises(ActionController::RoutingError) do
      get 'medias/embed/project/collection/item%20that$is@invalid'
    end
    assert_nothing_raised do
      get '/medias/embed/project/collection/item_THAT-is_v4l1d'
    end
  end

  test "should notify a project" do
    assert_recognizes({ controller: 'medias', action: 'notify', project: 'test-project' }, { path: 'medias/notify/test-project', method: :post })
  end

  test "should notify a collection" do
    assert_recognizes({ controller: 'medias', action: 'notify', project: 'test-project', collection: 'test-collection' }, { path: 'medias/notify/test-project/test-collection', method: :post })
  end

  test "should notify a single item" do
    assert_recognizes({ controller: 'medias', action: 'notify', project: 'test-project', collection: 'test-collection', item: 'test-item' }, { path: 'medias/notify/test-project/test-collection/test-item', method: :post })
  end

  test "should validate project format on notify" do
    assert_raises(ActionController::RoutingError) do
      post 'medias/notify/project%20that$is@invalid'
    end
    assert_nothing_raised do
      post '/medias/notify/project_THAT-is_v4l1d'
    end
  end

  test "should validate collect format on notify" do
    assert_raises(ActionController::RoutingError) do
      post 'medias/notify/project/collection%20that$is@invalid'
    end
    assert_nothing_raised do
      post '/medias/notify/project/collection_THAT-is_v4l1d'
    end
  end

  test "should validate item format on notify" do
    assert_raises(ActionController::RoutingError) do
      post 'medias/notify/project/collection/item%20that$is@invalid'
    end
    assert_nothing_raised do
      post '/medias/notify/project/collection/item_THAT-is_v4l1d'
    end
  end

  test "should validate Arabic collection on notify" do
    assert_nothing_raised do
      encoded = URI.encode('/medias/notify/project/عوده_الوايت_نايتس')
      post encoded 
    end
  end

  test "should be loaded through AJAX" do
    url = BRIDGE_CONFIG['bridgembed_host_private'] + '/medias/embed/google_spreadsheet/test.js'

    html = '<script src="//code.jquery.com/jquery-1.10.2.js"></script>' + 
           '<div id="embed"></div>' +
           '<a href="#" id="trigger">Embed</a>' +
           '<script>' +
           '  $("#trigger").click(function() {' +
           '     $.ajax({' +
           '       url: "/"' +
           '     }).done(function() {' +
           '       $("#embed").html("<script src=\"' + url + '\" type=\"text/javascript\"><\/script>");' +
           #'       $("#embed").html("<iframe src=\"' + url + '\"><\/iframe>");' +
           '     });' +
           '     return false;' +
           '  });' +
           '</script>'

    with_testing_page (html) do
      assert !page.has_css?('#embed iframe')
      page.click_link 'Embed'
      sleep 10.seconds
      assert page.has_css?('#embed iframe')
    end
  end

  test "should be loaded through AJAX using jQuery 1.4.4" do
    url = BRIDGE_CONFIG['bridgembed_host_private'] + '/medias/embed/google_spreadsheet/test'

    html = '<script src="//code.jquery.com/jquery-1.4.4.min.js"></script>' +
           '<div id="embed"></div>' +
           '<a href="#" id="trigger">Embed</a>' +
           '<script>' +
           '  $("#trigger").click(function() {' +
           '     $.ajax({' +
           '       url: "/",' +
           '       dataType: "html",' +
           '       success: function() {' +
           '         var url = "' + url + '",' +
           '             src = url + ".js",' +
           '             id = url.replace(/^.*\/medias\/embed\/([^.?]+)(\.|$|\?).*/, "$1").split("/").join("-"),' +
           '             script = "<script type=\"text/javascript\" src=\"" + src + "\"><\/script>",' +
           '             blockquote = "<blockquote id=\"bridge-embed-placeholder-" + id + "\" class=\"bridge-embed-placeholder\"><\/blockquote>";' +
           '         $("#embed").html(blockquote + script);' +
           '       }'+
           '     });' +
           '     return false;' +
           '  });' +
           '</script>'

    with_testing_page (html) do
      assert !page.has_css?('#embed iframe')
      page.click_link 'Embed'
      sleep 10.seconds
      assert page.has_css?('#embed iframe')
      assert !page.has_css?('blockquote')
    end
  end
end
