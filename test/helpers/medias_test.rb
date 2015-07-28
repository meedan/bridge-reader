require File.join(File.expand_path(File.dirname(__FILE__)), '..', 'test_helper')

class MediasHelperTest < ActionView::TestCase
  test "should parse translation and create link" do
    translation = { text: 'Visit http://meedan.com #now @dude!' }
    assert_equal '<p>Visit <a href="http://meedan.com" target="_blank">http://meedan.com</a> #now @dude!</p>', parse_translation(translation, 'other')
  end

  test "should parse Twitter translation" do
    translation = { text: 'Check @meedan, is #amazing!' }
    assert_equal '<p>Check <a href="https://twitter.com/meedan" target="_blank">@meedan</a>, is <a href="https://twitter.com/hashtag/amazing" target="_blank">#amazing</a>!</p>', parse_translation(translation, 'twitter')
  end

  test "should parse Instagram translation" do
    translation = { text: 'Check @meedan, is #amazing!' }
    assert_equal '<p>Check <a href="http://instagram.com/meedan" target="_blank">@meedan</a>, is #amazing!</p>', parse_translation(translation, 'instagram')
  end

  test "should not crash if provider has no custom parser" do
    translation = { text: 'Check @meedan, is #amazing!' }
    assert_equal '<p>Check @meedan, is #amazing!</p>', parse_translation(translation, 'other')
  end

  test "should parse markdown" do
    translation = { text: 'Markdown is *really* **cool**!' }
    assert_equal '<p>Markdown is <em>really</em> <strong>cool</strong>!</p>', parse_translation(translation, 'twitter')
  end

  test "should parse links in markdown" do
    text = 'Visit [Meedan](http://meedan.com) website!'
    assert_equal '<p>Visit <a href="http://meedan.com" target="_blank">Meedan</a> website!</p>', parse_text(text)
  end

  test "should not parse hashtags as Markdown title" do
    translation = { text: '#hashtag1 This should not be a header #hashtag2' }
    assert_equal '<p><a href="https://twitter.com/hashtag/hashtag1" target="_blank">#hashtag1</a> This should not be a header <a href="https://twitter.com/hashtag/hashtag2" target="_blank">#hashtag2</a></p>', parse_translation(translation, 'twitter')
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
    assert_equal 'rtl', get_text_direction({ text: 'مسيحيو الشرق الأوسط المختفين' }, 'other')
  end

  test "should return direction for ltr text" do
    assert_equal 'ltr', get_text_direction({ text: 'Left to right text' }, 'other')
  end

  test "should return direction for bi-directional text" do
    assert_equal 'rtl', get_text_direction({ text: 'ﻢﺴﻴﺤﻳﻭ ﺎﻠﺷﺮﻗ ﺍﻷﻮﺴﻃ ﺎﻠﻤﺨﺘﻔﻴﻧ with English' }, 'other')
  end
end
