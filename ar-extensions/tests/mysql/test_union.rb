require File.expand_path( File.join( File.dirname( __FILE__ ), '../test_helper') )

class UnionTest < TestCaseSuperClass
  fixtures 'books'

  def test_union_should_query_five_records
    books = Book.find_union({:conditions => ['author_name = ?', 'Terry Brooks']},
                    {:conditions => 'id > 3 and id < 6'})


    assert_equal(5, books.length)
    books.each {|book|
      assert(book.author_name == 'Terry Brooks' || (book.id > 3 && book.id < 6))
    }
  end


  def test_union_should_query_four_records
    books = Book.find_union({:conditions => ['author_name = ?', 'Terry Brooks']},
                            {:conditions => 'id > 3 and id < 6', :limit => 1})

    assert_equal(4, books.length)
    books.each {|book|
      assert(book.author_name == 'Terry Brooks' || (book.id > 3 && book.id < 6))
    }
  end

  def test_count_union_should_query_five_records_for_id
    count = Book.count_union(:id, {:conditions => ['author_name = ?', 'Terry Brooks']},
                    {:conditions => 'id > 3 and id < 6'})

    assert_equal(5, count)
  end

  def test_union_should_query_four_records_using_limit
    count = Book.count_union(:all,
                            {:conditions => ['author_name = ?', 'Terry Brooks']},
                            {:conditions => 'id > 3 and id < 6', :limit => 1})

    assert_equal(4, count)
  end

  def test_count_union_should_count_two_authors
    count = Book.count_union(:author_name, {:conditions => ['author_name = ?', 'Terry Brooks']},
                    {:conditions => 'id > 3 and id < 6'})

    assert_equal(2, count)
  end


end


