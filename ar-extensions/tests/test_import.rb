require File.expand_path( File.join( File.dirname( __FILE__ ), 'boot') )

class ImportTest < Test::Unit::TestCase
  if ActiveRecord::Base.connection.class.name =~ /sqlite/i
    self.use_transactional_fixtures = false
  end
  

  def setup
    @connection = ActiveRecord::Base.connection
    @columns_for_on_duplicate_key_update = [ 'id', 'title', 'author_name']
    Topic.destroy_all
  end
  
  def teardown
    Topic.destroy_all
  end

  def wrap_within_a_transaction(&blk)
    # sqlite doesn't support nested transactions. Since
    # postgresql is ritarded and requires people to manually
    # handle constraint exceptions we have to wrap the passed
    # in block in a transaction block. MySQL and PostgreSQL support
    # this fine. 
    #
    # TODO - find out from Michael Flester if Oracle supports this
    if Book.connection.class.name =~ /sqlite/i
      blk.call
    else
      Book.connection.transaction do
        blk.call
      end
    end
  end
  
  def test_quoted_column_names  
    column_names = %W{ col1 col2 }
    actual = ActiveRecord::Base.quote_column_names( column_names )

    expected = [ 
      @connection.quote_column_name( column_names.first ),
      @connection.quote_column_name( column_names.last ) ]
      
    assert_equal expected.first, actual.first
    assert_equal expected.last, actual.last
  end
  
  def import_test_column_names
     %W{ title author_name }
  end

  def import_topic_values
    # includes description and author's name
    [[ 'LDAP', 'Jerry Carter' ],
     [ 'Rails Recipes', 'Chad Fowler' ] ]
  end

  def test_import_without_validations
    columns = import_test_column_names
    values = import_topic_values

    expected_count = Topic.count + values.size
    Topic.import( columns, values, :validate=>false )
    assert_equal expected_count, Topic.count

    expected_ldap_topic,expected_ldap_author = values.first[0], values.first[1]
    expected_rails_topic,expected_rails_author = values.last[0], values.last[1]

    ldap_topic, rails_topic = Topic.find :all
    assert_equal expected_ldap_topic, ldap_topic.title
    assert_equal expected_ldap_author, ldap_topic.author_name
    assert_equal expected_rails_topic, rails_topic.title
    assert_equal expected_rails_author, rails_topic.author_name  
  end

  def test_import_with_validations
    columns, values = import_test_column_names, import_topic_values
    expected_count = Topic.count + values.size

    Topic.import( columns, values, :validate=>true )
    assert_equal expected_count, Topic.count

    expected_ldap_topic,expected_ldap_author = values.first[0], values.first[1]
    expected_rails_topic,expected_rails_author = values.last[0], values.last[1]

    ldap_topic, rails_topic = Topic.find :all
    assert_equal expected_ldap_topic, ldap_topic.title
    assert_equal expected_ldap_author, ldap_topic.author_name
    assert_equal expected_rails_topic, rails_topic.title
    assert_equal expected_rails_author, rails_topic.author_name  
  end

  # these are expected to fail
  def test_import_with_validations_that_fail
    columns = [ 'title' ]
    values = [['LDAP'],['Rails Recipes']] # missing author names, these should fail

    # these should fail, so we should end up with the same count for Topics
    expected_count = Topic.count
    result = Topic.import( columns, values, :validate=>true )
    invalid_topics = result.failed_instances
    
    assert_equal expected_count, Topic.count
    assert_equal values.size, invalid_topics.size
    invalid_topics.each{ |e| assert_kind_of Topic, e }
  end
  
  def test_import_with_array_of_model_objects
    topics = []
    (0..9).each{ |i| topics << Topic.new( :title=>"Book#{i}", :author_name=>"Someguy" ) }

    number_of_topics = Topic.count
    Topic.import( topics )
    
    assert_equal number_of_topics + topics.size, Topic.count
  end

  def test_import_with_array_of_model_objects_with_options
    topics = []
    (0..9).each{ |i| topics << Topic.new( :title=>"Book#{i}", :author_name=>"Someguy" ) }

    number_of_topics = Topic.count
    Topic.import( topics, :validate=>true )
    
    assert_equal number_of_topics + topics.size, Topic.count
  end  

  def test_import_with_array_of_column_names_and_array_of_model_objects
    topic = Topic.new :title=>"Book", :author_name=>"Someguy", :author_email_address=>"me@me.com"
    topic2 = Topic.new :title=>"Book2", :author_name=>"Someguy2", :author_email_address=>"me2@me.com"
    
    assert_equal 0, Topic.count
    Topic.import( [ :title ], [ topic, topic2 ], :validate => false )
    assert_equal 2, Topic.count
  end

  def test_get_insert_value_sets
    base_sql = "INSERT INTO atable (a,b,c)"
    values = [ '(1,2,3)','(2,3,4)', '(3,4,5)' ]

    max_allowed_bytes = 33
    value_sets = ActiveRecord::ConnectionAdapters::AbstractAdapter.get_insert_value_sets( values, base_sql.size, max_allowed_bytes )
    assert_equal 3, value_sets.size
    
    max_allowed_bytes = 40
    value_sets = ActiveRecord::ConnectionAdapters::AbstractAdapter.get_insert_value_sets( values, base_sql.size, max_allowed_bytes )
    assert_equal 3, value_sets.size

    max_allowed_bytes = 41
    value_sets = ActiveRecord::ConnectionAdapters::AbstractAdapter.get_insert_value_sets( values, base_sql.size, max_allowed_bytes )
    assert_equal 2, value_sets.size

    max_allowed_bytes = 48
    value_sets = ActiveRecord::ConnectionAdapters::AbstractAdapter.get_insert_value_sets( values, base_sql.size, max_allowed_bytes )
    assert_equal 2, value_sets.size

    max_allowed_bytes = 49
    value_sets = ActiveRecord::ConnectionAdapters::AbstractAdapter.get_insert_value_sets( values, base_sql.size, max_allowed_bytes )
    assert_equal 1, value_sets.size

    max_allowed_bytes = 999999
    value_sets = ActiveRecord::ConnectionAdapters::AbstractAdapter.get_insert_value_sets( values, base_sql.size, max_allowed_bytes )
    assert_equal 1, value_sets.size
  end

  def test_import_with_default_validation_should_return_a_number_of_inserts
    values = [[ "LDAP", "Bird Bird" ]]
    result = Topic.import [:title, :author_name], values
    assert_equal 1, result.num_inserts, "wrong number of inserts"
  end

  def test_import_with_validation_should_return_a_number_of_inserts
   values = [["LDAP", "Bird Bird"]]
   result = Topic.import [:title, :author_name], values, :validation=>false
   assert_equal 1, result.num_inserts, "wrong number of inserts"
  end

  def test_import_without_validation_should_return_a_number_of_inserts
   values = [["LDAP", "Bird Bird"]]
   result = Topic.import [:title, :author_name], values, :validation=>true
   assert_equal 1, result.num_inserts, "wrong number of inserts"
  end
  
  def test_import_should_automatically_update_created_on_columns_for_new_imported_records
    Book.destroy_all
    
    start_time = Time.now
    Book.import [:title, :author_name, :publisher], [["LDAP", "Big Bird", "Del Rey"]]
    stop_time = Time.now
    
    book = Book.find(:first)
    assert_within start_time.to_f-1, book.created_on.to_f, stop_time.to_f+1, "Book created time was incorrect"    
  end

  def test_import_should_automatically_update_created_at_columns_for_new_imported_records
    Book.destroy_all
    assert_equal 0, Book.count
    
    start_time = Time.now
    Book.import [:title, :author_name, :publisher], [["LDAP", "Big Bird", "Del Rey"]]
    stop_time = Time.now

    book = Book.find(:first)
    assert_within start_time.to_f-1, book.created_at.to_f, stop_time.to_f+1, "Book created time was incorrect"    
  end
  
  def test_import_should_automatically_update_updated_on_columns_for_new_imported_records
    Book.destroy_all
    
    start_time = Time.now
    Book.import [:title, :author_name, :publisher], [["LDAP", "Big Bird", "Del Rey"]]
    stop_time = Time.now
    
    book = Book.find(:first)
    assert_within start_time.to_f-1, book.updated_on.to_f, stop_time.to_f+1, "Book created time was incorrect"    
  end

  def test_import_should_automatically_update_updated_at_columns_for_new_imported_records
    Book.destroy_all
    
    start_time = Time.now
    Book.import [:title, :author_name, :publisher], [["LDAP", "Big Bird", "Del Rey"]]
    stop_time = Time.now
    
    book = Book.find(:first)
    assert_within start_time.to_f-1, book.updated_at.to_f, stop_time.to_f+1, "Book created time was incorrect"    
  end  
  
  def test_import_should_automatically_update_created_on_columns_for_new_imported_records_using_utc
    Book.destroy_all

    old_tz = ActiveRecord::Base.default_timezone
    ActiveRecord::Base.default_timezone = :utc        
    start_time = Time.now.utc
    Book.import [:title, :author_name, :publisher], [["LDAP", "Big Bird", "Del Rey"]]
    stop_time = Time.now.utc
    
    book = Book.find(:first)
    ActiveRecord::Base.default_timezone = old_tz
    assert_within start_time.to_f-1, book.created_on.to_f, stop_time.to_f+1, "Book created time was incorrect"    
  end

  def test_import_should_automatically_update_created_at_columns_for_new_imported_records_using_utc
    Book.destroy_all
    
    old_tz = ActiveRecord::Base.default_timezone
    ActiveRecord::Base.default_timezone = :utc        
    start_time = Time.now.utc
    Book.import [:title, :author_name, :publisher], [["LDAP", "Big Bird", "Del Rey"]]
    stop_time = Time.now.utc
    
    book = Book.find(:first)
    ActiveRecord::Base.default_timezone = old_tz
    assert_within start_time.to_f-1, book.created_at.to_f, stop_time.to_f+1, "Book created time was incorrect"    
  end
  
  def test_import_should_automatically_update_updated_on_columns_for_new_imported_records_using_utc
    Book.destroy_all
    
    old_tz = ActiveRecord::Base.default_timezone
    ActiveRecord::Base.default_timezone = :utc        
    start_time = Time.now.utc
    Book.import [:title, :author_name, :publisher], [["LDAP", "Big Bird", "Del Rey"]]
    stop_time = Time.now.utc
    
    book = Book.find(:first)
    ActiveRecord::Base.default_timezone = old_tz
    assert_within start_time.to_f-1, book.updated_on.to_f, stop_time.to_f+1, "Book created time was incorrect"    
  end

  def test_import_should_automatically_update_updated_at_columns_for_new_imported_records_using_utc
    Book.destroy_all
    
    old_tz = ActiveRecord::Base.default_timezone
    ActiveRecord::Base.default_timezone = :utc        
    start_time = Time.now.utc
    Book.import [:title, :author_name, :publisher], [["LDAP", "Big Bird", "Del Rey"]]
    stop_time = Time.now.utc
    
    book = Book.find(:first)
    ActiveRecord::Base.default_timezone = old_tz
    assert_within start_time.to_f-1, book.updated_at.to_f, stop_time.to_f+1, "Book created time was incorrect"    
  end  
  
  def test_import_should_not_add_or_overwrite_existing_models
    book = nil
    wrap_within_a_transaction do
      Book.destroy_all
      book = Book.create! :title=>"book1", :author_name=>"Zach", :publisher=>"Pub"
      assert_equal 1, Book.count
    end

    wrap_within_a_transaction do
      book.title = "New Title"
      begin
         Book.import [ book ]
      rescue Exception
      end
    end
    assert_equal 1, Book.count
  
    book.reload
    assert_equal "book1", book.title, "the title of the book shouldn't have changed since it was an existing record"
  end

  def test_import_should_add_nonsaved_models
    Book.destroy_all
    
    book = Book.new :title=>"book1", :author_name=>"Zach", :publisher=>"Pub"
    assert_equal 0, Book.count

    Book.import [ book ]
    assert_equal 1, Book.count
    
    book = Book.find(:first)
    assert_equal "book1", book.title
    assert_equal "Zach", book.author_name
    assert_equal "Pub", book.publisher
  end


  private
  
  def assert_within low, mid, high, msg=""
    assert (low < mid && mid < high), msg
  end
  
end

