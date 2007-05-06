require File.expand_path( File.join( File.dirname( __FILE__ ), 'boot' ) )

class SynchronizeTest < Test::Unit::TestCase
  include ActiveRecord::ConnectionAdapters
  self.fixture_path = File.join( File.dirname( __FILE__ ), 'fixtures/unit/synchronize' )
  self.fixtures 'books'

  def setup
    @connection = ActiveRecord::Base.connection
  end

  def test_synchronize
    books = [ Book.find(1), Book.find(2), Book.find(3) ]
    titles = books.map(&:title)
    
    @connection.execute( "UPDATE #{Book.table_name} SET title='#{titles[0]}_haha' WHERE id=#{books[0].id}", "Updating records without ActiveRecord" )  
    @connection.execute( "UPDATE #{Book.table_name} SET title='#{titles[1]}_haha' WHERE id=#{books[1].id}", "Updating records without ActiveRecord" )  
    @connection.execute( "UPDATE #{Book.table_name} SET title='#{titles[2]}_haha' WHERE id=#{books[2].id}", "Updating records without ActiveRecord" )  
    Book.synchronize( books )

    actual_titles = books.map(&:title)
    assert_equal "#{titles[0]}_haha", actual_titles[0], "the record was not correctly updated"
    assert_equal "#{titles[1]}_haha", actual_titles[1], "the record was not correctly updated"
    assert_equal "#{titles[2]}_haha", actual_titles[2], "the record was not correctly updated"
  end
  
end
