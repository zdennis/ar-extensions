require File.expand_path( File.join( File.dirname( __FILE__ ), 'test_helper' ) )

class FindersTest < Test::Unit::TestCase
  include ActiveRecord::ConnectionAdapters

  def setup
    @connection = ActiveRecord::Base.connection
  end

  def test_activerecord_model_can_be_used_with_reserved_words
    group1 = Group.create!(:order => "x")
    group2 = Group.create!(:order => "y")
    x = nil
    assert_nothing_raised { x = Group.new }
    x.order = 'x'
    assert_nothing_raised { x.save }
    x.order = 'y'
    assert_nothing_raised { x.save }
    assert_nothing_raised { y = Group.find_by_order('y') }
    assert_nothing_raised { y = Group.find(group2.id) }
    x = Group.find(group1.id)
  end
end
