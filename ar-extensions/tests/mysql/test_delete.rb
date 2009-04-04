require File.expand_path( File.join( File.dirname( __FILE__ ), '../test_helper') )

{:execute => [/^SELECT currval/, /^SELECT CAST/, /^SELECT @@IDENTITY/],
 :insert => [],
 :delete => []
}.each do |method, ignore_list|

  ActiveRecord::Base.connection.class.class_eval <<-END_SRC
    cattr_accessor :#{method}_count
    # Array of regexes of queries that are not counted against query_count
    @@ignore_#{method}_list = #{ignore_list.inspect}
    alias_method :#{method}_without_query_counting, :#{method}
    def #{method}_with_query_counting(sql, name = nil, &block)
      self.#{method}_count += 1 unless @@ignore_#{method}_list.any? { |r| sql =~ r }
      #{method}_without_query_counting(sql, name, &block)
    end
  END_SRC
end

class DeleteTestCaseSuperClass < TestCaseSuperClass
  protected

  def assert_query(method, num = 1)
    ActiveRecord::Base.connection.class.class_eval do
      self.send "#{method}_count=", 0
      alias_method method, "#{method}_with_query_counting"
    end
    yield
  ensure
    ActiveRecord::Base.connection.class.class_eval do
      alias_method method, "#{method}_without_query_counting"
    end
    count = ActiveRecord::Base.connection.send "#{method}_count"
    assert_equal num, count, "#{count} instead of #{num} #{method} queries were executed."
  end

end


class DeleteTest < DeleteTestCaseSuperClass

  def setup
    super
    insert_books
  end
  
  def test_delete_limit_should_only_delete_three_records
    count = Book.count(:all, :conditions => ['author_name = ?', 'giraffe'])
    assert_equal 50, count

    deleted = Book.delete_all(['author_name = ?', 'giraffe'], :limit => 24)

    assert_equal 24, deleted

    count = Book.count(:all, :conditions => ['author_name = ?', 'giraffe'])
    assert_equal 26, count
  end

  def test_delete_limit_should_delete_less_than_limit
    count = Book.count(:all, :conditions => ['author_name = ?', 'giraffe'])
    assert_equal 50, count

    deleted = Book.delete_all(['author_name = ?', 'giraffe'], :limit => 55)
    assert_equal(50, deleted)

    count = Book.count(:all, :conditions => ['author_name = ?', 'giraffe'])
    assert_equal 0, count
  end

  def test_delete_batch_should_execute_6_deletes
    assert_query(:delete, 6){
      assert_equal(50, Book.delete_all(nil, :batch => 10))
    }
    assert_equal 0, Book.count
  end

  def test_delete_batch_with_limit_should_delete_until_limit_reached
    assert_query(:delete, 4){
      assert_equal(32, Book.delete_all('id > 0', :batch => 10, :limit => 32))
    }
    assert_equal 18, Book.count
  end


  def test_delete_batch_default_should_delete_all
    assert_query(:delete, 1){
      assert_equal(50, Book.delete_all(nil, :batch => true))
    }
    assert_equal 0, Book.count
  end


  def test_delete_batch_bigger_than_limit_should_delete_limit
    assert_query(:delete, 1){
      assert_equal(12, Book.delete_all(nil, :batch => 20, :limit => 12))
    }
    assert_equal 38, Book.count
  end


  def test_delete_duplicates_should_leave_one_by_author_with_low_id
    min_id = Book.minimum :id

    Book.delete_duplicates(:fields => [:author_name])
    assert_equal 0, Book.count(:all, :group => :author_name, :having => 'count(*) > 1' ).length

    assert_equal(min_id, Book.find_by_author_name('giraffe').id)
  end


  def test_delete_duplicates_should_delete_all_but_one_with_publisher_one

    min_id = Book.minimum :id

    Book.delete_duplicates(:fields => [:author_name], :conditions => ['c1.publisher = ? and c2.publisher = ?', 'Pub1', 'Pub1'])

    books = Book.find_all_by_author_name('giraffe', :order => :id)
    assert_equal 41, books.length

    assert_equal min_id, books.first.id

    assert_equal 1, Book.find_all_by_author_name_and_publisher('giraffe', 'Pub1').length

  end

  def test_delete_duplicates_should_delete_all_but_five
    Book.delete_duplicates(:fields => [:author_name, :publisher])
    assert_equal(5, Book.count)
  end



  protected
  def insert_books
    Book.delete_all
    1.upto(50){|count|
      Book.create!(:author_name => 'giraffe', :title => "Title#{count}", :publisher => "Pub#{count % 5}")
    }
  end

end

