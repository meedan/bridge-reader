require File.join(File.expand_path(File.dirname(__FILE__)), '..', 'test_helper')

class SampleSource < Sources::Base
end

class BaseTest < ActiveSupport::TestCase

  def setup
    super
    @s = SampleSource.new('test', {})
  end

  test "should not instantiate base directly" do
    assert_raises RuntimeError do
      Sources::Base.new('test', {})
    end
  end

  test "should instantiate child class" do
    assert_nothing_raised do
      SampleSource.new('test', {})
    end
  end

  test "should get string representation" do
    assert_kind_of String, @s.to_s
  end

  test "should get project" do
    assert_equal [], @s.get_project
  end

  test "should get collection" do
    assert_equal [], @s.get_collection('test')
  end

  test "should get item" do
    assert_equal({}, @s.get_item('test', 'test'))
  end
end
