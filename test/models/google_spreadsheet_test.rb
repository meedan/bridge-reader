require File.join(File.expand_path(File.dirname(__FILE__)), '..', 'test_helper')

class GoogleSpreadsheetTest < ActiveSupport::TestCase
  def setup
    super
    @b = Sources::GoogleSpreadsheet.new('google_spreadsheet', BRIDGE_PROJECTS['google_spreadsheet'])
    @b.get_worksheet('test')
  end

  test "should initialize" do
    assert_not_nil @b.instance_variable_get(:@worksheet)
    assert_not_nil @b.instance_variable_get(:@session)
    assert_not_nil @b.instance_variable_get(:@spreadsheet)
    assert_nil @b.instance_variable_get(:@worksheets)
  end

  test "should authenticate" do
    assert_equal @b.instance_variable_get(:@session), @b.authenticate
  end

  test "should get spreadsheet" do
    assert_equal @b.instance_variable_get(:@spreadsheet), @b.get_spreadsheet(BRIDGE_PROJECTS['google_spreadsheet']['google_spreadsheet_id'])
  end

  test "should get title" do
    assert_equal @b.instance_variable_get(:@title), @b.get_title('test')
  end

  test "should get worksheet" do
    assert_equal @b.instance_variable_get(:@worksheet), @b.get_worksheet('test')
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
    comment_text = 'Caio won first place on this contest.

Not big deal, actually.'
    translation = entries.first[:translations].first
    comment = entries.first[:translations].first[:comments].first
    assert_equal text, translation[:text]
    assert_equal comment_text, comment[:comment]
    assert_equal '', translation[:translator_name]
    assert_equal 'http://ca.ios.ba', translation[:translator_url]
    assert_equal 'Caio', comment[:commenter_name]
    assert_equal '', comment[:commenter_url]

    translation = entries[1][:translations].first
    comment = entries[1][:translations].first[:comments].first
    assert_equal 'Because the sky is blue', entries[1][:source_text]
    assert_equal 'http://instagram.com/p/tP5h3kvHTi/', entries[1][:link]
    assert_equal 'Porque o céu é azul', translation[:text]
    assert_equal 'This is a palm tree on Salvador', comment[:comment]
    assert_equal 'Caio Almeida', translation[:translator_name]
    assert_equal 'http://ca.ios.ba', translation[:translator_url]
    assert_equal 'Caio', comment[:commenter_name]
    assert_equal 'http://twitter.com/caiosba', comment[:commenter_url]
  end

  test "should get worksheets" do
    assert @b.get_worksheets.map(&:title).include?('test')
  end

  test "should initialize with configuration" do
    b = Sources::GoogleSpreadsheet.new('google_spreadsheet', BRIDGE_PROJECTS['google_spreadsheet'])
    assert_not_nil b.instance_variable_get(:@config)
  end

  test "should mark unavailable link as such" do
    w = @b.get_worksheet('test')
    (1..4).each do |i|
      w[i, 9] = ''
      w.save
      assert w[i, 9].blank?
    end
    entries = @b.get_entries
    @b.notify_availability(entries[0], true)
    @b.notify_availability(entries[1], true)
    @b.notify_availability(entries[2], false)
    @b.notify_availability(entries[3], false)
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

    assert !File.exists?(@b.cache_path('google_spreadsheet', 'test', 'bdfe8a5559bd3e44987188b1c5e85113c52bfe14'))
    assert !File.exists?(@b.cache_path('google_spreadsheet', 'test', ''))

    @b.generate_cache(@b, 'google_spreadsheet', 'test', 'bdfe8a5559bd3e44987188b1c5e85113c52bfe14')
    @b.generate_cache(@b, 'google_spreadsheet', 'test', '')
    
    assert File.exists?(@b.cache_path('google_spreadsheet', 'test', 'bdfe8a5559bd3e44987188b1c5e85113c52bfe14'))
    assert File.exists?(@b.cache_path('google_spreadsheet', 'test', ''))
    
    @b.send(:notify_link_condition, 'http://instagram.com/p/pwcow7AjL3/', 'check404')
    
    w.reload
    assert_equal 'Yes', w[5, 9]
    
    assert !File.exists?(@b.cache_path('google_spreadsheet', 'test', 'bdfe8a5559bd3e44987188b1c5e85113c52bfe14'))
    assert File.exists?(@b.cache_path('google_spreadsheet', 'test', ''))
  end

  test "should notify that spreadsheet was updated" do
    assert !File.exists?(@b.cache_path('google_spreadsheet', 'test', ''))
    @b.send(:notify_link_condition, 'https://docs.google.com/a/meedan.com/spreadsheets/d/1_YfkPjumE2CgNmzGpGirYgFPb--IaR9r4cNn5PNb3lM/edit#test', 'check_google_spreadsheet_updated')
    assert File.exists?(@b.cache_path('google_spreadsheet', 'test', ''))
  end

  test "should send to watchbot when generating cache if file does not exist" do
    Sources::GoogleSpreadsheet.any_instance.expects(:notify_new_item).once
    clear_cache
    @b.generate_cache(@b, 'google_spreadsheet', 'test', '')
  end

  test "should not send to watchbot when generating cache if file exists" do
    Sources::GoogleSpreadsheet.any_instance.expects(:notify_new_item).never
    create_cache
    @b.generate_cache(@b, 'google_spreadsheet', 'test', '')
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
    assert_not_equal [], @b.get_entries('183773d82423893d9409faf05941bdbd63eb0b5c')
  end

  test "should not get link" do
    assert_equal [], @b.get_entries('183773d82423893d9409faf05941bdbd63eb0b5x')
  end

  test "should refresh entries" do
    @b.get_entries('183773d82423893d9409faf05941bdbd63eb0b5c')
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
      Sources::GoogleSpreadsheet.new('test', BRIDGE_PROJECTS['google_spreadsheet'])
    end
  end
end
