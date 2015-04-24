require File.join(File.expand_path(File.dirname(__FILE__)), '..', 'test_helper')

class MediasHelperTest < ActionView::TestCase
  test "should parse translation and create link" do
    translation = { translation: 'Visit http://meedan.com #now @dude!' }
    assert_equal '<p>Visit <a href="http://meedan.com" target="_blank">http://meedan.com</a> #now @dude!</p>', parse_translation(translation)
  end

  test "should parse Twitter translation" do
    translation = { translation: 'Check @meedan, is #amazing!', provider: 'twitter' }
    assert_equal '<p>Check <a href="https://twitter.com/meedan" target="_blank">@meedan</a>, is <a href="https://twitter.com/hashtag/amazing" target="_blank">#amazing</a>!</p>', parse_translation(translation)
  end

  test "should parse Instagram translation" do
    translation = { translation: 'Check @meedan, is #amazing!', provider: 'instagram' }
    assert_equal '<p>Check <a href="http://instagram.com/meedan" target="_blank">@meedan</a>, is #amazing!</p>', parse_translation(translation)
  end

  test "should not crash if provider has no custom parser" do
    translation = { translation: 'Check @meedan, is #amazing!', provider: 'other' }
    assert_equal '<p>Check @meedan, is #amazing!</p>', parse_translation(translation)
  end

  test "should parse markdown" do
    translation = { translation: 'Markdown is *really* **cool**!' }
    assert_equal '<p>Markdown is <em>really</em> <strong>cool</strong>!</p>', parse_translation(translation)
  end

  test "should parse links in markdown" do
    text = 'Visit [Meedan](http://meedan.com) website!'
    assert_equal '<p>Visit <a href="http://meedan.com" target="_blank">Meedan</a> website!</p>', parse_text(text)
  end

  test "should not parse hashtags as Markdown title" do
    translation = { translation: '#hashtag1 This should not be a header #hashtag2', provider: 'twitter' }
    assert_equal '<p><a href="https://twitter.com/hashtag/hashtag1" target="_blank">#hashtag1</a> This should not be a header <a href="https://twitter.com/hashtag/hashtag2" target="_blank">#hashtag2</a></p>', parse_translation(translation)
  end
end
