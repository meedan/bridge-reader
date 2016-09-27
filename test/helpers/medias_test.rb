require File.join(File.expand_path(File.dirname(__FILE__)), '..', 'test_helper')

class MediasHelperTest < ActionView::TestCase
  test "should parse translation and create link" do
    text = 'Visit http://meedan.com #now @dude!'
    assert_equal '<p>Visit <a href="http://meedan.com" target="_blank">http://meedan.com</a> #now @dude!</p>', parse_text_provider(text, 'other')
  end

  test "should parse Twitter translation" do
    text = 'Check @meedan, is #amazing!'
    assert_equal '<p>Check <a href="https://twitter.com/meedan" target="_blank">@meedan</a>, is <a href="https://twitter.com/hashtag/amazing" target="_blank">#amazing</a>!</p>', parse_text_provider(text, 'twitter')
  end

  test "should parse Instagram translation" do
    text = 'Check @meedan, is #amazing!'
    assert_equal '<p>Check <a href="http://instagram.com/meedan" target="_blank">@meedan</a>, is <a href="https://instagram.com/explore/tags/amazing" target="_blank">#amazing</a>!</p>', parse_text_provider(text, 'instagram')
  end

  test "should not crash if provider has no custom parser" do
    text = 'Check @meedan, is #amazing!'
    assert_equal '<p>Check @meedan, is #amazing!</p>', parse_text_provider(text, 'other')
  end

  test "should parse markdown" do
    text = 'Markdown is *really* **cool**!'
    assert_equal '<p>Markdown is <em>really</em> <strong>cool</strong>!</p>', parse_text_provider(text, 'twitter')
  end

  test "should parse links in markdown" do
    text = 'Visit [Meedan](http://meedan.com) website!'
    assert_equal '<p>Visit <a href="http://meedan.com" target="_blank">Meedan</a> website!</p>', parse_text(text)
  end

  test "should not parse hashtags as Markdown title" do
    text = '#hashtag1 This should not be a header #hashtag2'
    assert_equal '<p><a href="https://twitter.com/hashtag/hashtag1" target="_blank">#hashtag1</a> This should not be a header <a href="https://twitter.com/hashtag/hashtag2" target="_blank">#hashtag2</a></p>', parse_text_provider(text, 'twitter')
  end

  test "should shorten URL return long" do
    short = short_url_for('foo', 'bar', 'jksdahdiu6786378ygdsuyt387e673eywgdwsyutwds836s8273seujlkjf3827e376rs876wekhdjwhsi628r7')
    assert_not_equal 'bit.ly', URI.parse(short).host
  end

  test "should shorten URL return short" do
    stub_config 'bridgembed_host', 'https://bridge-embed.dev.meedan.net' 
    short = short_url_for('ooew', 'test', 'c291f649aa5625b81322207177a41e2c4a08f09d.png')
    assert_equal 'bit.ly', URI.parse(short).host
  end

  test "should return direction for rtl text" do
    assert_equal 'rtl', get_translation_direction({ text: 'مسيحيو الشرق الأوسط المختفين' }, 'other')
  end

  test "should return direction for ltr text" do
    assert_equal 'ltr', get_translation_direction({ text: 'Left to right text' }, 'other')
  end

  test "should return direction for bi-directional text" do
    assert_equal 'rtl', get_translation_direction({ text: 'ﻢﺴﻴﺤﻳﻭ ﺎﻠﺷﺮﻗ ﺍﻷﻮﺴﻃ ﺎﻠﻤﺨﺘﻔﻴﻧ with English' }, 'other')
  end

  test "should return direction for rtl comment" do
    assert_equal 'rtl', get_comment_direction({ comment: 'مسيحيو الشرق الأوسط المختفين' })
  end

  test "should return direction for ltr comment" do
    assert_equal 'ltr', get_comment_direction({ comment: 'Left to right text' })
  end

  test "should return direction for bi-directional comment" do
    assert_equal 'rtl', get_comment_direction({ comment: 'ﻢﺴﻴﺤﻳﻭ ﺎﻠﺷﺮﻗ ﺍﻷﻮﺴﻃ ﺎﻠﻤﺨﺘﻔﻴﻧ with English' })
  end

  test "should add Google Analytics tag" do
    stub_config 'google_analytics_code', 'UA-12345678-1'
    assert_match /script/, include_google_analytics_tag
  end

  test "should not add Google Analytics tag" do
    stub_config 'google_analytics_code', ''
    assert_equal '', include_google_analytics_tag
  end

  test "should parse Twitter with two hashtags with underline" do
    text = 'This is a #hash_tag and #another_hash_tag'
    assert_equal '<p>This is a <a href="https://twitter.com/hashtag/hash_tag" target="_blank">#hash_tag</a> and <a href="https://twitter.com/hashtag/another_hash_tag" target="_blank">#another_hash_tag</a></p>', parse_text_provider(text, 'twitter')
  end

  test "should not parse Instagram hashtags as header" do
    text = '#Sanliurfa #Halfeti, #Euphrates #River #Hidden #Heaven #underwater #lostcity #hometown #boat'
    output = "<p><a href=\"https://instagram.com/explore/tags/Sanliurfa\" target=\"_blank\">#Sanliurfa</a> <a href=\"https://instagram.com/explore/tags/Halfeti\" target=\"_blank\">#Halfeti</a>, <a href=\"https://instagram.com/explore/tags/Euphrates\" target=\"_blank\">#Euphrates</a> <a href=\"https://instagram.com/explore/tags/River\" target=\"_blank\">#River</a> <a href=\"https://instagram.com/explore/tags/Hidden\" target=\"_blank\">#Hidden</a> <a href=\"https://instagram.com/explore/tags/Heaven\" target=\"_blank\">#Heaven</a> <a href=\"https://instagram.com/explore/tags/underwater\" target=\"_blank\">#underwater</a> <a href=\"https://instagram.com/explore/tags/lostcity\" target=\"_blank\">#lostcity</a> <a href=\"https://instagram.com/explore/tags/hometown\" target=\"_blank\">#hometown</a> <a href=\"https://instagram.com/explore/tags/boat\" target=\"_blank\">#boat</a></p>"
    assert_equal output, parse_text_provider(text, 'instagram')
  end

  test "should parse line breaks markdown" do
    text = "Line 1\nLine 2\nLine 3\nLine 4\n\nLine 5"
    assert_equal '<p>Line 1<br />Line 2<br />Line 3<br />Line 4</p><p>Line 5</p>', parse_text_provider(text, 'twitter')
  end

  test "should render approval stamp if translation is approved" do
    translation = { approval: { 'approved' => '1' } }
    assert_not_equal '', reviewed_stamp(translation)
  end

  test "should not render approval stamp if translation is not approved" do
    translation = { approval: { 'approved' => '' } }
    assert_equal '', reviewed_stamp(translation)
  end
end
