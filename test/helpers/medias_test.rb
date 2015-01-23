require File.join(File.expand_path(File.dirname(__FILE__)), '..', 'test_helper')

class MediasHelperTest < ActionView::TestCase
  test "should parse translation and create link" do
    translation = { translation: 'Visit http://meedan.com #now @dude!' }
    assert_equal 'Visit <a href="http://meedan.com" target="_blank">http://meedan.com</a> #now @dude!', parse_translation(translation)
  end

  test "should parse Twitter translation" do
    translation = { translation: 'Check @meedan, is #amazing!', provider: 'twitter' }
    assert_equal 'Check <a href="https://twitter.com/meedan" target="_blank">@meedan</a>, is <a href="https://twitter.com/hashtag/amazing" target="_blank">#amazing</a>!', parse_translation(translation)
  end

  test "should parse Instagram translation" do
    translation = { translation: 'Check @meedan, is #amazing!', provider: 'instagram' }
    assert_equal 'Check <a href="http://instagram.com/meedan" target="_blank">@meedan</a>, is #amazing!', parse_translation(translation)
  end

  test "should not crash if provider has no custom parser" do
    translation = { translation: 'Check @meedan, is #amazing!', provider: 'other' }
    assert_equal 'Check @meedan, is #amazing!', parse_translation(translation)
  end
end
