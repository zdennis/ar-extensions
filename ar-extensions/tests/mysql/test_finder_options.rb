require File.expand_path( File.join( File.dirname( __FILE__ ), '..', 'test_helper' ))


class FinderOptionsTest < TestCaseSuperClass
  include ActiveRecord::ConnectionAdapters
  self.fixture_path = File.join( File.dirname( __FILE__ ), 'fixtures/unit/active_record_base_finders' )
  self.fixtures 'books'

  def setup
    @connection = ActiveRecord::Base.connection
  end
  
  def teardown
    Topic.delete_all
    Book.delete_all
  end
  
  def test_find_with_having_should_add_having_option_to_sql
    create_books_and_topics
    
    #test having without associations
    books = Book.find(:all, :select => 'count(*) as count_all, topic_id', :group => :topic_id, :having => 'count(*) > 1')
    assert_equal 2, books.size
    
    #test having with associations
    books = Book.find(:all, 
      :include => :topic, 
      :conditions => " topics.id is not null", #the conditions forces eager loading in Rails 2.2
      :select => 'count(*) as count_all, topic_id',
      :group => :topic_id,
      :having => 'count(*) > 1')
      
    assert_equal 2, books.size
  end

  def test_finder_sql_to_string_should_select_from_one_table
    book_sql = Book.finder_sql_to_string(:select => 'topic_id', :include => :topic)

    # current generated output looks like this now:
    # SELECT topic_id FROM `books`
    assert(/^SELECT\s/.match(book_sql))
    assert_nil(/\sJOIN\s/.match(book_sql))
    (Book.column_names - ['topic_id']).each do |col|
      assert_nil(book_sql.match(Regexp.new("^SELECT .*[`\s]#{col}.*FROM")))
    end

    assert(/^SELECT\s.*topic_id.*FROM/.match(book_sql))
  end

  def test_finder_sql_to_string_w_forced_eager_load_should_generate_sql_with_joined_table
    book_sql = Book.finder_sql_to_string(:select => 'topic_id',
                                         :include => :topic,
                                         :force_eager_load => true)
    assert(/^SELECT\s/.match(book_sql))
    assert(/\sJOIN\s/.match(book_sql))

    #assert that each column was included in the sql
    Book.column_names.each do |col|
      assert(book_sql.match(Regexp.new("^SELECT .*[`\s\.]#{col}.*FROM")))
    end
    
    # current generated output looks like this now:
    # SELECT `books`.`id` AS t0_r0, `books`.`title` AS t0_r1, `books`.`publisher` AS t0_r2, `books`.`author_name` AS t0_r3, `books`.`created_at` AS t0_r4, `books`.`created_on` AS t0_r5, `books`.`updated_at` AS t0_r6, `books`.`updated_on` AS t0_r7, `books`.`topic_id` AS t0_r8, `books`.`for_sale` AS t0_r9, `topics`.`id` AS t1_r0, `topics`.`title` AS t1_r1, `topics`.`author_name` AS t1_r2, `topics`.`author_email_address` AS t1_r3, `topics`.`written_on` AS t1_r4, `topics`.`bonus_time` AS t1_r5, `topics`.`last_read` AS t1_r6, `topics`.`content` AS t1_r7, `topics`.`approved` AS t1_r8, `topics`.`replies_count` AS t1_r9, `topics`.`parent_id` AS t1_r10, `topics`.`type` AS t1_r11, `topics`.`created_at` AS t1_r12, `topics`.`updated_at` AS t1_r13 FROM `books`  LEFT OUTER JOIN `topics` ON `topics`.id = `books`.topic_id
  end

  def test_finder_sql_to_string_should_generate_sql_with_joined_table
    conditions = 'topics.id is not null'
    book_sql = Book.finder_sql_to_string(:select => 'topic_id', :include => :topic, :conditions => conditions)
    
    assert(/^SELECT\s/.match(book_sql))
    assert(/\sJOIN\s/.match(book_sql))
    assert(book_sql.include?(conditions))

    #assert that each column was included in the sql
    Book.column_names.each do |col|
      assert(book_sql.match(Regexp.new("^SELECT .*[`\s\.]#{col}.*FROM")))
    end
    
    # current generated output looks like this now:
    #"SELECT `books`.`id` AS t0_r0, `books`.`title` AS t0_r1, `books`.`publisher` AS t0_r2, `books`.`author_name` AS t0_r3, `books`.`created_at` AS t0_r4, `books`.`created_on` AS t0_r5, `books`.`updated_at` AS t0_r6, `books`.`updated_on` AS t0_r7, `books`.`topic_id` AS t0_r8, `books`.`for_sale` AS t0_r9, `topics`.`id` AS t1_r0, `topics`.`title` AS t1_r1, `topics`.`author_name` AS t1_r2, `topics`.`author_email_address` AS t1_r3, `topics`.`written_on` AS t1_r4, `topics`.`bonus_time` AS t1_r5, `topics`.`last_read` AS t1_r6, `topics`.`content` AS t1_r7, `topics`.`approved` AS t1_r8, `topics`.`replies_count` AS t1_r9, `topics`.`parent_id` AS t1_r10, `topics`.`type` AS t1_r11, `topics`.`created_at` AS t1_r12, `topics`.`updated_at` AS t1_r13 FROM `books`  LEFT OUTER JOIN `topics` ON `topics`.id = `books`.topic_id WHERE (topics.id is not null)"
  end
  
  def test_pre_sql_should_ensure_pre_sql_option_is_added_to_beginning_of_sql
    book_sql = Book.finder_sql_to_string(:select => 'topic_id', :pre_sql => "/* BLAH */")
    assert(/^\/\* BLAH \*\/\sSELECT/.match(book_sql))
  end

  def test_pre_sql_should_ensure_pre_sql_option_is_added_to_beginning_of_sql_with_eager_loading
    book_sql = Book.finder_sql_to_string(:select => 'topic_id', :pre_sql => "/* BLAH */", :include => :topic, :conditions => 'topics.id is not null')
    assert(/^\/\* BLAH \*\/\sSELECT/.match(book_sql))
  end
  
  def test_pre_sql_should_ensure_post_sql_option_is_added_to_end_of_sql
    book_sql = Book.finder_sql_to_string(:select => 'topic_id', :post_sql => "/* BLAH */")
    assert(/\s\/\* BLAH \*\/$/.match(book_sql))
  end

  def test_pre_sql_should_ensure_post_sql_option_is_added_to_end_of_sql_with_eager_loading
    book_sql = Book.finder_sql_to_string(:select => 'topic_id', :post_sql => "/* BLAH */", :include => :topic, :conditions => 'topics.id is not null')
    assert(/\s\/\* BLAH \*\/$/.match(book_sql))
  end
  
  protected
  
  def create_books_and_topics
    Book.destroy_all
    Topic.destroy_all
    
    topics = [Topic.create!(:title => 'My Topic', :author_name => 'Giraffe'),
              Topic.create!(:title => 'Other Topic', :author_name => 'Giraffe'),
              Topic.create!(:title => 'Last Topic', :author_name => 'Giraffe')]
   
    Book.create!(:title => 'Title A', :topic_id => topics[0].to_param, :author_name => 'Giraffe')
    Book.create!(:title => 'Title B', :topic_id => topics[0].to_param, :author_name => 'Giraffe')
    Book.create!(:title => 'Title C', :topic_id => topics[0].to_param, :author_name => 'Giraffe')
    Book.create!(:title => 'Title D', :topic_id => topics[1].to_param, :author_name => 'Giraffe')
    Book.create!(:title => 'Title E', :topic_id => topics[1].to_param, :author_name => 'Giraffe')
    Book.create!(:title => 'Title F', :topic_id => topics[2].to_param, :author_name => 'Giraffe')
  end
  
end
