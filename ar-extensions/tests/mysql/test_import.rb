require File.expand_path( File.join( File.dirname( __FILE__ ), '..', 'boot') )

class ActiveRecordBaseTest < Test::Unit::TestCase

  def setup
    @connection = ActiveRecord::Base.connection
    @columns_for_on_duplicate_key_update = [ 'id', 'title', 'author_name']
    Topic.delete_all
  end
  
  def teardown
    Topic.delete_all
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

  
end
