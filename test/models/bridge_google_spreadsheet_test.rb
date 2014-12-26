require File.join(File.expand_path(File.dirname(__FILE__)), '..', 'test_helper')
load File.join(File.expand_path(File.dirname(__FILE__)), '..', '..', 'lib', 'bridge_google_spreadsheet.rb')
require 'bridge_google_spreadsheet'

class BridgeGoogleSpreadsheetTest < ActiveSupport::TestCase

  def setup
    @b = Bridge::GoogleSpreadsheet.new(BRIDGE_CONFIG['google_email'],
                                       BRIDGE_CONFIG['google_password'],
                                       BRIDGE_CONFIG['google_spreadsheet_id'],
                                       'test')
  end

  test "should initialize" do
    assert_not_nil @b.instance_variable_get(:@worksheet)
    assert_not_nil @b.instance_variable_get(:@session)
    assert_not_nil @b.instance_variable_get(:@spreadsheet)
  end

  test "should authenticate" do
    assert_equal @b.instance_variable_get(:@session), @b.authenticate(BRIDGE_CONFIG['google_email'], BRIDGE_CONFIG['google_password'])
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

  test "should get update at" do
    assert_kind_of Integer, @b.updated_at
  end

  test "should get URLs" do
    urls = @b.get_urls
    assert_equal 2, urls.size
    assert_equal 'https://twitter.com/caiosba/status/548252845238398976', urls.first
    assert_equal 'http://instagram.com/p/tP5h3kvHTi/', urls.last
  end

  test "should get entries" do
    entries = @b.get_entries
    assert_equal 2, entries.size
    assert_equal 'Feliz Natal! Ressuscitando um cartão que eu fiz há 10 anos pra participar de um concurso de arte digital. Tempo voa!',
                 entries.first[:source_text]
    assert_equal 'https://twitter.com/caiosba/status/548252845238398976', entries.first[:link]
    assert_equal 'Merry Christmas! Reviving a card that I did 10 years ago to join a digital art contest. Time flies!',
                 entries.first[:translation]
    assert_equal 'Caio won first place on this contest.', entries.first[:comment]
    assert_equal 'Caio Almeida', entries.first[:translator_name]
    assert_equal 'http://ca.ios.ba', entries.first[:translator_url]
    assert_equal 'Because the sky is blue', entries.last[:source_text]
    assert_equal 'http://instagram.com/p/tP5h3kvHTi/', entries.last[:link]
    assert_equal 'Porque o céu é azul', entries.last[:translation]
    assert_equal 'This is a palm tree on Salvador', entries.last[:comment]
    assert_equal 'Caio Almeida', entries.last[:translator_name]
    assert_equal 'http://ca.ios.ba', entries.last[:translator_url]
  end

end
