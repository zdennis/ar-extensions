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

  def test_union_with_unused_include_should_query_five_records
    books = Book.find_union({:conditions => ['author_name = ?', 'Terry Brooks']},
                    {:conditions => 'books.id > 3 and books.id < 6', :include => :topic})


    assert_equal(5, books.length)
    books.each {|book|
      assert(book.author_name == 'Terry Brooks' || (book.id > 3 && book.id < 6))
    }
  end


  def test_union_with_include_should_load_5_books
    @topic = Topic.create!(:title => 'funtimes', :author_name => 'giraffe')
    Book.update_all(['topic_id = ? ', @topic.id], ['books.id > 3 and books.id < 6'])


    books = Book.find_union({:conditions => ['author_name = ?', 'Terry Brooks']},
                    {:conditions => ['topics.title = :name',{:name => @topic.title}],
                     :include => ['topic']})


    assert_equal(5, books.length)

    books.each {|book|
      assert(book.author_name == 'Terry Brooks' || (book.id > 3 && book.id < 6))
    }
  end

  def test_union_with_limit_should_query_four_records
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


