require File.join( File.dirname( __FILE__ ), 'boot' )

class ActiveRecordBaseFinderTest < Test::Unit::TestCase
  include ActiveRecord::ConnectionAdapters

  fixtures 'developers'

  def setup
    @connection = ActiveRecord::Base.connection
  end

  def teardown
    Developer.delete( :all )
  end

  def test_find_by_array
    developers = Developer.find( :all, :conditions=>{ :id=>[1,2] } )
    assert_equal( 2, developers.size )
  end

  def test_find_by_range
    # there is no difference between ( x..z ) and ( x...z )
    developers = Developer.find( :all, :conditions=>{ :id=>(1..2) } )
    assert_equal( 2, developers.size )
    developers = Developer.find( :all, :conditions=>{ :id=>(1...2) } )
    assert_equal( 2, developers.size )
  end

  def test_find_with_like
    developers = Developer.find( :all, :conditions=>{ :name_like=>'ach' } )
    assert_equal( 1, developers.size )

    developers = Developer.find( :all, :conditions=>{ :name_like=>'Zach' } )
    assert_equal( 1, developers.size )
  end

  def test_find_with_starts_with
    developers = Developer.find( :all, :conditions=>{ :name_starts_with=>'Zach' } )
    assert_equal( 1, developers.size )

    # we shouldn't find a record which starts with the last name Dennis
    developers = Developer.find( :all, :conditions=>{ :name_starts_with=>'Dennis' } )
    assert_equal( 0, developers.size )
  end

  def test_find_with_ends_with
    developers = Developer.find( :all, :conditions=>{ :name_ends_with=>'Dennis' } )
    assert_equal( 1, developers.size )

    # we shouldn't find an issue which ends with the first name Zach
    developers = Developer.find( :all, :conditions=>{ :name_ends_with=>'Zach' } )
    assert_equal( 0, developers.size )
  end

  def test_find_with_regex
    developers = Developer.find( :all, :conditions=>{ :name=>/^Zach/ } )
    assert_equal( 1, developers.size )

    developers = Developer.find( :all, :conditions=>{ :name=>/Dennis$/ } )
    assert_equal( 1, developers.size )
  end

  def test_find_with_less_than
    developers = Developer.find( :all, :conditions=>{ :id_lt=>2 } )
    assert_equal( 1, developers.size )
  end

  def test_find_with_greater_than
    developers = Developer.find( :all, :conditions=>{ :id_gt=>1 } )
    assert_equal( 1, developers.size )
  end

  def test_find_with_less_than_or_equal_to
    developers = Developer.find( :all, :conditions=>{ :id_lte=>2 } )
    assert_equal( 2, developers.size )
  end

  def test_find_with_greater_than_or_equal_to
    developers = Developer.find( :all, :conditions=>{ :id_gte=>1 } )
    assert_equal( 2, developers.size )
  end

  def test_find_not_equal_to
    developers = Developer.find( :all, :conditions=>{ :id_ne=>9999 } )
    assert_equal( Developer.count, developers.size )

     developers = Developer.find( :all, :conditions=>{ :id_not=>9999 } )
    assert_equal( Developer.count, developers.size )
  end

  def test_find_not_in_array
    developers = Developer.find( :all, :conditions=>{ :id_ne=>[ 9999 ] } )
    assert_equal( Developer.count, developers.size )

    developers = Developer.find( :all, :conditions=>{ :id_not=>[ 9999 ] } )
    assert_equal( Developer.count, developers.size )
  end

  def test_find_not_in_range
    developers = Developer.find( :all, :conditions=>{ :id_ne=>( 9998..9999 ) } )
    assert_equal( Developer.count, developers.size )

    developers = Developer.find( :all, :conditions=>{ :id_not=>( 9998..9999 ) } )
    assert_equal( Developer.count, developers.size )
  end

  def test_find_not_matching_regex
    developers = Developer.find( :all, :conditions=>{ :name_ne=>/9999/ } )
    assert_equal( Developer.count, developers.size )

    developers = Developer.find( :all, :conditions=>{ :name_not=>/9999/ } )
    assert_equal( Developer.count, developers.size )
  end

  def test_find_with_string_and_hash
    developers = Developer.find( :all, 
      :conditions=>[ "name = 'Zach Dennis'", { :id=>1 } ] )
    assert_equal( 1, developers.size )
  end

  def test_find_with_string_and_hash_where_none_match
    developers = Developer.find( :all, 
      :conditions=>[ "id = 1", { :id=>2 } ] )
    assert_equal( 0, developers.size )
  end

  def test_find_with_string_and_hash_where_string_uses_hash_values
    developers = Developer.find( :all, 
      :conditions=>[ "id = :id", { :id=>1 } ] )
    assert_equal( 1, developers.size )
  end
  
end
