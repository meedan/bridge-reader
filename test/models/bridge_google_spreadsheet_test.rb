require File.join(File.expand_path(File.dirname(__FILE__)), '..', 'test_helper')
load File.join(File.expand_path(File.dirname(__FILE__)), '..', '..', 'lib', 'bridge_google_spreadsheet.rb')
require 'bridge_google_spreadsheet'

class BridgeGoogleSpreadsheetTest < ActiveSupport::TestCase
  def setup
    super
    @b = Bridge::GoogleSpreadsheet.new(BRIDGE_CONFIG['google_spreadsheet_id'], 'test')
    @all = Bridge::GoogleSpreadsheet.new(BRIDGE_CONFIG['google_spreadsheet_id'])
  end

  test "should initialize" do
    assert_not_nil @b.instance_variable_get(:@worksheet)
    assert_not_nil @b.instance_variable_get(:@session)
    assert_not_nil @b.instance_variable_get(:@spreadsheet)
    assert_nil @b.instance_variable_get(:@worksheets)
  end

  test "should authenticate" do
    assert_equal @b.instance_variable_get(:@session), @b.authenticate('test')
  end

  test "should get spreadsheet" do
    assert_equal @b.instance_variable_get(:@spreadsheet), @b.get_spreadsheet(BRIDGE_CONFIG['google_spreadsheet_id'])
  end

  test "should get title" do
    assert_equal @b.instance_variable_get(:@title), @b.get_title('test')
  end

  test "should get worksheet" do
    assert_equal @b.instance_variable_get(:@worksheet), @b.get_worksheet('test')
  end

  test "should get URLs" do
    urls = @b.get_urls
    assert_equal 4, urls.size
    assert_equal 'https://twitter.com/caiosba/status/548252845238398976', urls.first
    assert_equal 'http://instagram.com/p/tP5h3kvHTi/', urls[1]
  end

  test "should get entries" do
    entries = @b.get_entries
    assert_equal 4, entries.size
    
    assert_equal 'Feliz Natal! Ressuscitando um cartão que eu fiz há 10 anos pra participar de um concurso de arte digital. Tempo voa!',
                 entries.first[:source_text]
    assert_equal 'https://twitter.com/caiosba/status/548252845238398976', entries.first[:link]
    text = 'Merry Christmas!

Reviving a card that I did 10 years ago to join a digital art contest.

Time flies!'
    comment = 'Caio won first place on this contest.

Not big deal, actually.'
    assert_equal text, entries.first[:translation]
    assert_equal comment, entries.first[:comment]
    assert_equal '', entries.first[:translator_name]
    assert_equal 'http://ca.ios.ba', entries.first[:translator_url]
    assert_equal 'Caio', entries.first[:commenter]
    assert_equal '', entries.first[:commenter_url]
    
    assert_equal 'Because the sky is blue', entries[1][:source_text]
    assert_equal 'http://instagram.com/p/tP5h3kvHTi/', entries[1][:link]
    assert_equal 'Porque o céu é azul', entries[1][:translation]
    assert_equal 'This is a palm tree on Salvador', entries[1][:comment]
    assert_equal 'Caio Almeida', entries[1][:translator_name]
    assert_equal 'http://ca.ios.ba', entries[1][:translator_url]
    assert_equal 'Caio', entries[1][:commenter]
    assert_equal 'http://twitter.com/caiosba', entries[1][:commenter_url]
  end

  test "should get worksheets" do
    assert @b.get_worksheets.map(&:title).include?('test')
  end

  test "should initialize without milestone" do
    b = Bridge::GoogleSpreadsheet.new(BRIDGE_CONFIG['google_spreadsheet_id'])
    assert_not_nil b.instance_variable_get(:@worksheets)
    assert_nil b.instance_variable_get(:@worksheet)
  end

  test "should mark unavailable link as such" do
    w = @b.get_worksheet('test')
    (1..4).each do |i|
      w[i, 9] = ''
      w.save
      assert w[i, 9].blank?
    end
    @b.notify_availability(2, true)
    @b.notify_availability(3, true)
    @b.notify_availability(4, false)
    @b.notify_availability(5, false)
    assert_equal 'Unavailable?', w[1, 9]
    assert_equal 'No', w[2, 9]
    assert_equal 'No', w[3, 9]
    assert_equal 'Yes', w[4, 9]
    assert_equal 'Yes', w[5, 9]
  end

  test "should return title when casting to string" do
    assert_equal 'test', @b.to_s
  end

  test "should notify that link is offline" do
    w = @b.get_worksheet('test')
    w[5, 9] = 'No'
    w.save
    clear_cache
    assert !cache_file_exists?
    path = File.join('public', 'cache', 'link', 'bdfe8a5559bd3e44987188b1c5e85113c52bfe14.html')
    assert !File.exists?(path)
    @b.notify_link_condition('http://instagram.com/p/pwcow7AjL3/', 'check404')
    w.reload
    assert cache_file_exists?
    assert_equal 'Yes', w[5, 9]
    assert File.exists?(path)
  end

  test "should get url" do
    assert_kind_of String, @b.url
    assert_equal 'docs.google.com', URI.parse(@b.url).host
  end

  test "should send to watchbot" do
    Bridge::Watchbot.any_instance.expects(:send).once
    @b.send_to_watchbot
  end

  test "should notify that spreadsheet was updated" do
    w = @b.get_worksheet('test')
    clear_cache
    assert !cache_file_exists?
    path = File.join('public', 'cache', 'link', 'bdfe8a5559bd3e44987188b1c5e85113c52bfe14.html')
    assert !File.exists?(path)
    @b.notify_link_condition('https://docs.google.com/a/meedan.com/spreadsheets/d/1qpLfypUaoQalem6i3SHIiPqHOYGCWf2r7GFbvkIZtvk/edit#test', 'check_google_spreadsheet_updated')
    assert cache_file_exists?
    assert File.exists?(path)
  end

  test "should send to watchbot when generating cache if file does not exist" do
    Bridge::GoogleSpreadsheet.any_instance.expects(:send_to_watchbot).once
    clear_cache
    @b.generate_cache(@b, 'milestone', 'test')
  end

  test "should not send to watchbot when generating cache if file exists" do
    Bridge::GoogleSpreadsheet.any_instance.expects(:send_to_watchbot).never
    create_cache
    @b.generate_cache(@b, 'milestone', 'test')
  end

  test "should get cache path" do
    assert_match /milestone\/test\.html$/, @b.cache_path('milestone', @b.get_worksheet.title)
    assert_match /link\/foo\.html$/, @b.cache_path('link', 'foo')
  end

  test "should get a single entry" do
    entries = @b.get_entries('183773d82423893d9409faf05941bdbd63eb0b5c')
    assert_equal 1, entries.size
  end

  test "should get nothing if link does not exist" do
    entries = @b.get_entries('hdgsahd78d67sa6dasdgasgjdjd78e6tyudas87d')
    assert_equal 0, entries.size
  end

  test "should get link" do
    assert_not_nil @all.get_link('183773d82423893d9409faf05941bdbd63eb0b5c')
  end

  test "should not get link" do
    assert_nil @all.get_link('183773d82423893d9409faf05941bdbd63eb0b5x')
  end

  test "should get link from cache if available" do
    all = @all.get_worksheets
    Bridge::GoogleSpreadsheet.any_instance.expects(:get_worksheets).returns(all).once
    hash = '183773d82423893d9409faf05941bdbd63eb0b5c'
    assert_nil Rails.cache.read(hash)
    link1 = @all.get_link(hash)
    assert_not_nil Rails.cache.read(hash)
    link2 = @all.get_link(hash)
    assert_equal link1, link2
  end

  test "should refresh entries" do
    @b.get_link('183773d82423893d9409faf05941bdbd63eb0b5c')
    assert_equal 1, @b.get_entries.size
    @b.get_entries(nil, true)
    assert_equal 4, @b.get_entries.size
  end

  test "should get access token" do
    Rails.cache.delete('!google_access_token')
    assert_kind_of String, @b.send(:generate_google_access_token)
  end

  test "should refresh token" do
    Rails.cache.expects(:fetch).returns('invalid token')
    assert_nothing_raised do
      Bridge::GoogleSpreadsheet.new(BRIDGE_CONFIG['google_spreadsheet_id'], 'test')
    end
  end
end
