require File.expand_path( File.join( File.dirname( __FILE__ ), 'boot') )

class ActiveRecordBaseTest < Test::Unit::TestCase

  def setup
    @connection = ActiveRecord::Base.connection
    @columns_for_on_duplicate_key_update = [ 'id', 'title', 'author_name']
    Topic.delete_all
  end
  
  def teardown
    Topic.delete_all
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
    invalid_topics = Topic.import( columns, values, :validate=>true )
    
    assert_equal expected_count, Topic.count
    assert_equal values.size, invalid_topics.size
    invalid_topics.each{ |e| assert_kind_of Topic, e }
    

  end
  
  # sets up base data for on duplicate key update tests
  def setup_import_without_validations_but_with_on_duplicate_key_update
    columns = @columns_for_on_duplicate_key_update    
    values = [ [ 1, 'Book', 'Author' ] ]
    Topic.import( columns, values, :validate=>false )
    Topic.find_by_id( 1 )
  end
  
  def test_import_without_validations_but_with_on_duplicate_key_update_using_string_array1
    return unless Topic.supports_on_duplicate_key_update?

    orig_topic = setup_import_without_validations_but_with_on_duplicate_key_update
    columns = @columns_for_on_duplicate_key_update
    
    # The author_name is NOT supposed to change.
    columns2update = [ 'title' ]
    updated_values = [ [ 1, 'Book - 2nd Edition', 'New Author' ] ]
    Topic.import( columns, updated_values, 
      :validate=>false,
      :on_duplicate_key_update=>columns2update )
    topic = Topic.find_by_id( 1 )
    assert_equal updated_values[0][1], topic.title, "The book title is wrong! It was supposed to change!"
    assert_equal orig_topic.author_name, topic.author_name, "The author's name is incorrect! It wasn't supposed to change!"
 

  end
 
  def test_import_without_validations_but_with_on_duplicate_key_update_using_string_array2
    return unless Topic.supports_on_duplicate_key_update?
 
    setup_import_without_validations_but_with_on_duplicate_key_update
    columns = @columns_for_on_duplicate_key_update
 
    # note that both the title and the author name should change here
    columns2update = [ 'title', 'author_name' ]
    updated_values = [ [ 1, 'Book - 2nd Edition', 'New Author' ] ]
    Topic.import( columns, updated_values, 
      :validate=>false,
      :on_duplicate_key_update=>columns2update )
    topic = Topic.find_by_id( 1 )
    assert_equal updated_values[0][1], topic.title, "The book title is wrong! It was supposed to change!"
    assert_equal updated_values[0][2], topic.author_name, "The author's name is incorrect! It was supposed to change!"
    
 
  end    
  
  def test_import_without_validations_but_with_on_duplicate_key_update_using_symbol_array1
    return unless Topic.supports_on_duplicate_key_update?
    
    orig_topic = setup_import_without_validations_but_with_on_duplicate_key_update
    columns = @columns_for_on_duplicate_key_update
 
    # test updates with array with symbol(s) *note that author_name isn't supposed to change
    columns2update = [ :title ]
    updated_values = [ [ 1, 'Book - 3rd Edition', 'New Author' ] ]
    Topic.import( columns, updated_values, 
      :validate=>false,
      :on_duplicate_key_update=>columns2update )
    topic = Topic.find_by_id( 1 )
    assert_equal updated_values[0][1], topic.title, "The book title is wrong! It was supposed to change!"
    assert_equal orig_topic.author_name, topic.author_name, "The author's name is incorrect! It wasn't supposed to change!"
    
 
  end    
   
  def test_import_without_validations_but_with_on_duplicate_key_update_using_symbol_array2
    return unless Topic.supports_on_duplicate_key_update?
    
    orig_topic = setup_import_without_validations_but_with_on_duplicate_key_update
    columns = @columns_for_on_duplicate_key_update
 
    # Note that the title and author's name are supposed to change unlik the previous assertion
    columns2update = [ :title, :author_name ]
    updated_values = [ [ 1, 'Book - 4th Edition', 'New Author' ] ]
    Topic.import( columns, updated_values, 
      :validate=>false,
      :on_duplicate_key_update=>columns2update )
    topic = Topic.find_by_id( 1 )
    assert_equal updated_values[0][1], topic.title, "The book title is wrong! It was supposed to change!"
    assert_equal updated_values[0][2], topic.author_name, "The author's name is incorrect! It was supposed to change!"
   

  end
  
  def test_import_without_validations_but_with_on_duplicate_key_update_using_string_hash1
    return unless Topic.supports_on_duplicate_key_update?
    
    orig_topic = setup_import_without_validations_but_with_on_duplicate_key_update
    columns = @columns_for_on_duplicate_key_update
 
    # Note that the title is supposed to change but NOT the author's name
    columns2update = { 'title'=>'title' }
    updated_values = [ [ 1, 'Book - 5th Edition', 'New Author' ] ]
    Topic.import( columns, updated_values, 
      :validate=>false,
      :on_duplicate_key_update=>columns2update )
    topic = Topic.find_by_id( 1 )
    assert_equal updated_values[0][1], topic.title, "The book title is wrong! It was supposed to change!"
    assert_equal orig_topic.author_name, topic.author_name, "The author's name is incorrect! It wasn't supposed to change!"
   

  end

  def test_import_without_validations_but_with_on_duplicate_key_update_using_string_hash2
    return unless Topic.supports_on_duplicate_key_update?
    
    orig_topic = setup_import_without_validations_but_with_on_duplicate_key_update
    columns = @columns_for_on_duplicate_key_update
 
    # Note that the title is supposed to change to the author's name, but the
    # author's name is NOT supposed to change
    columns2update = { 'title'=>'author_name' }
    updated_values = [ [ 1, 'Book - 6th Edition', 'New Author' ] ]
    Topic.import( columns, updated_values, 
      :validate=>false,
      :on_duplicate_key_update=>columns2update )
    topic = Topic.find_by_id( 1 )
    assert_equal updated_values[0][2], topic.title, "The book title is wrong! It was supposed to change to the author's name!"
    assert_equal orig_topic.author_name, topic.author_name, "The author's name is incorrect! It wasn't supposed to change!"
   

  end
  
  def test_import_without_validations_but_with_on_duplicate_key_update_using_string_hash3
    return unless Topic.supports_on_duplicate_key_update?
    
    orig_topic = setup_import_without_validations_but_with_on_duplicate_key_update
    columns = @columns_for_on_duplicate_key_update
 
    # Note that the title AND the author_name is supposed to change
    columns2update = { 'title'=>'title', 'author_name'=>'author_name' }
    updated_values = [ [ 1, 'Book - 7th Edition', 'New Author' ] ]
    Topic.import( columns, updated_values, 
      :validate=>false,
      :on_duplicate_key_update=>columns2update )
    topic = Topic.find_by_id( 1 )
    assert_equal updated_values[0][1], topic.title, "The book title is wrong! It was supposed to change!"
    assert_equal updated_values[0][2], topic.author_name, "The author's name is incorrect! It was supposed to change!"
   

  end
  
  def test_import_without_validations_but_with_on_duplicate_key_update_using_symbol_hash1
    return unless Topic.supports_on_duplicate_key_update?
    
    orig_topic = setup_import_without_validations_but_with_on_duplicate_key_update
    columns = @columns_for_on_duplicate_key_update
 
    # Note that the title is supposed to change but NOT the author's name
    columns2update = { :title=>:title }
    updated_values = [ [ 1, 'Book - 8th Edition', 'New Author' ] ]
    Topic.import( columns, updated_values, 
      :validate=>false,
      :on_duplicate_key_update=>columns2update )
    topic = Topic.find_by_id( 1 )
    assert_equal updated_values[0][1], topic.title, "The book title is wrong! It was supposed to change!"
    assert_equal orig_topic.author_name, topic.author_name, "The author's name is incorrect! It wasn't supposed to change!"
   

  end

  def test_import_without_validations_but_with_on_duplicate_key_update_using_symbol_hash2
    return unless Topic.supports_on_duplicate_key_update?
    
    orig_topic = setup_import_without_validations_but_with_on_duplicate_key_update
    columns = @columns_for_on_duplicate_key_update
 
    # Note that the title is supposed to change to the author's name, but the
    # author's name is NOT supposed to change
    columns2update = { :title=>:author_name }
    updated_values = [ [ 1, 'Book - 9th Edition', 'New Author' ] ]
    Topic.import( columns, updated_values, 
      :validate=>false,
      :on_duplicate_key_update=>columns2update )
    topic = Topic.find_by_id( 1 )
    assert_equal updated_values[0][2], topic.title, "The book title is wrong! It was supposed to change to the author's name!"
    assert_equal orig_topic.author_name, topic.author_name, "The author's name is incorrect! It wasn't supposed to change!"
  end
  
  def test_import_without_validations_but_with_on_duplicate_key_update_using_symbol_hash3
    return unless Topic.supports_on_duplicate_key_update?
    orig_topic = setup_import_without_validations_but_with_on_duplicate_key_update
    columns = @columns_for_on_duplicate_key_update
 
    # Note that the title AND the author_name is supposed to change
    columns2update = { :title=>:title, :author_name=>:author_name }
    updated_values = [ [ 1, 'Book - 10th Edition', 'New Author' ] ]
    Topic.import( columns, updated_values, 
      :validate=>false,
      :on_duplicate_key_update=>columns2update )
    topic = Topic.find_by_id( 1 )
    assert_equal updated_values[0][1], topic.title, "The book title is wrong! It was supposed to change!"
    assert_equal updated_values[0][2], topic.author_name, "The author's name is incorrect! It was supposed to change!"
   
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
  
  def test_import_with_array_of_model_objects_with_on_duplicate_key_update
    return unless Topic.supports_on_duplicate_key_update?
    
    topic = Topic.create( :title=>"Book", :author_name=>"Someguy" ) 
    topic2 = Topic.create( :title=>"Book2", :author_name=>"Someguy" ) 

    topic.author_name = "SomeNewguy"
    topic2.author_name = "SomeOtherNewguy"
  
    Topic.import( [ topic, topic2 ], :on_duplicate_key_update=>[ :author_name ] )
    topic.reload
    topic2.reload
  
    assert_equal "SomeNewguy", topic.author_name
    assert_equal "SomeOtherNewguy", topic2.author_name
  end  

  def test_import_with_array_of_column_names_and_array_of_model_objects
    
    topic = Topic.new :title=>"Book", :author_name=>"Someguy", :author_email_address=>"me@me.com"
    topic2 = Topic.new :title=>"Book2", :author_name=>"Someguy2", :author_email_address=>"me2@me.com"
    
    assert_equal 0, Topic.count
    Topic.import( [ :title ], [ topic, topic2 ], :validate => false )
    assert_equal 2, Topic.count
  end
  
  
end

