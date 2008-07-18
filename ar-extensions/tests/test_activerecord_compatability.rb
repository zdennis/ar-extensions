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
  
  def test_find_on_hash_conditions_with_explicit_table_name
    group1 = Group.create!(:order => "x")
    assert Group.find(group1.id, :conditions => { "group.order" => "x" })
    assert_raises(ActiveRecord::RecordNotFound) { 
      Group.find(group1.id, :conditions => { 'group.order' => "y" }) 
    }
  end

  def test_exists_with_aggregate_having_three_mappings
    topic = Topic.create! :title => "SomeBook", :author_name => "Joe Smith"
    assert Topic.exists?(:description => topic.description)

    topic = Topic.new :title => "MayDay", :author_name => "Joe Smith the 2nd"
    assert !Topic.exists?(:description => topic.description)
  end
  
  def test_find_with_aggregate
    topic = Topic.create! :title => "SomeBook", :author_name => "Joe Smith"
    assert_equal topic, Topic.find(:first, :conditions => { :description => topic.description })

    topic = Topic.new :title => "MayDay", :author_name => "Joe Smith the 2nd"
    assert !Topic.find(:first, :conditions => { :description => topic.description })
  end
  
end
