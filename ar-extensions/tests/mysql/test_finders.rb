require File.expand_path( File.join( File.dirname( __FILE__ ), '..', 'test_helper' ) )

class MysqlFindersTest< TestCaseSuperClass
  include ActiveRecord::ConnectionAdapters
  self.fixture_path = File.join( File.dirname( __FILE__ ), '../fixtures/unit/active_record_base_finders' )
  self.fixtures :books

  def setup
    @connection = ActiveRecord::Base.connection
  end
  
  def teardown
    Book.delete_all
  end

  # FIXME this won't work until full text index/searching is added for 
  #   any db adapter outside of MySQL.
  # For PostgreSQL support look into TSearch2 support which is
  # builtin to PostgreSQL 8.x (but not in 7.x)
  def test_find_three_results_using_match
    unless Book.supports_full_text_searching?
      STDERR.puts "test_find_three_results_using_match is not testing, since your database adapter doesn't support fulltext searching"
    else
      books = Book.find( :all, :conditions=>{ :match_title=> 'Terry' } )
      assert_equal( 4, books.size )
    end
  end

end
