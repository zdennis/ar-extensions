require File.expand_path( File.join( File.dirname( __FILE__ ), '..', 'test_helper') )

class MysqlImportTest< TestCaseSuperClass
  fixtures :topics, :books

  def setup
    @connection = ActiveRecord::Base.connection
    @columns_for_on_duplicate_key_update = [ 'id', 'title', 'author_name']
    Topic.delete_all
  end
  
  def teardown
    Topic.delete_all
    Book.delete_all
  end

  # sets up base data for on duplicate key update tests
  def setup_import_without_validations_but_with_on_duplicate_key_update
    columns = @columns_for_on_duplicate_key_update    
    values = [ [ 1, 'Book', 'Author' ] ]
    Topic.import( columns, values, :validate=>false )
    Topic.find_by_id( 1 )
  end
 
  def test_import_without_validations_but_with_on_duplicate_key_update_that_synchronizes_existing_AR_instances
    topics = []
    topics << Topic.create!( :title=>"LDAP", :author_name=>"Big Bird" )
    topics << Topic.create!( :title=>"Rails Recipes", :author_name=>"Elmo") 
      
    columns = %W{ id author_name }
    values = []
    values << [ topics.first.id, "Jerry Carter" ]
    values << [ topics.last.id, "Chad Fowler" ]
    
    columns2update = [ 'author_name' ]
      
    expected_count = Topic.count
    Topic.import( columns, values,
      :validate=>false,
      :on_duplicate_key_update=>columns2update,
      :synchronize=>topics )
    
    assert_equal expected_count, Topic.count, "no new records should have been created!"
    assert_equal "Jerry Carter",  topics.first.author_name, "wrong author!"
    assert_equal "Chad Fowler", topics.last.author_name, "wrong author!"
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
  
  def test_import_without_validations_but_with_on_duplicate_key_update_using_associated_objects
    return unless Topic.supports_on_duplicate_key_update?

    topic1 = Topic.create( :title=>"Topic1", :author_name=>"Someguy" ) 
    topic2 = Topic.create( :title=>"Topic2", :author_name=>"Someguy" ) 

    book1 = Book.create :title=>"book1", :author_name=>"Zach", :publisher=>"Pub", :topic_id=>topic1.id
    book2 = Book.create :title=>"book2", :author_name=>"Mark", :publisher=>"Pub", :topic_id=>topic1.id
    
    book1.topic = topic2
    book2.topic = topic1
    
    # Note that the title is supposed to change
    columns = [ :id, :title, :author_name, :topic_id ]
    columns2update = [ :title, :author_name, :topic_id ]
    updated_values = [ 
      [ book1.id, 'Book - 1st Edition', 'New Author', book1.topic.id ],
      [ book2.id, 'Book - 2nd Edition', 'New Author', book2.topic.id ] ]
    Book.import( columns, updated_values, 
      :validate=>false,
      :on_duplicate_key_update=>columns2update )

    book1.reload
    book2.reload
    
    assert_equal updated_values[0][1], book1.title, "The book title is wrong! It was supposed to change!"
    assert_equal updated_values[0][2], book1.author_name, "The author's name is incorrect! It was supposed to change!"
    assert_equal updated_values[0][3], book1.topic_id, "The topic id is wrong!"
    
    assert_equal updated_values[1][1], book2.title, "The book title is wrong! It was supposed to change!"
    assert_equal updated_values[1][2], book2.author_name, "The author's name is incorrect! It was supposed to change!"
    assert_equal updated_values[1][3], book2.topic_id, "The topic id is wrong!"
  end  
  
  def test_import_with_on_duplicate_key_update_with_associated_objects_saves_foreign_keys
    return unless Topic.supports_on_duplicate_key_update?

    topic1 = Topic.create( :title=>"Topic1", :author_name=>"Someguy" ) 
    topic2 = Topic.create( :title=>"Topic2", :author_name=>"Someguy" ) 

    book1 = Book.create :title=>"book1", :author_name=>"Zach", :publisher=>"Pub", :topic_id=>topic1.id
    book2 = Book.create :title=>"book2", :author_name=>"Mark", :publisher=>"Pub", :topic_id=>topic1.id
    book3 = Book.create :title=>"book3", :author_name=>"Zach", :publisher=>"Pub", :topic_id=>topic1.id
    
    book1.topic = topic2
    book2.topic = topic1
    book3.topic = topic2
    
    books = [ book1, book2, book3 ]
    Book.import( books, :on_duplicate_key_update=>[ :topic_id ])
    books.each{ |b| b.reload }

    assert book1.topic_id == topic2.id, "wrong topic id for book1!"
    assert book2.topic_id == topic1.id, "wrong topic id for book2!"
    assert book3.topic_id == topic2.id, "wrong topic id for book3!"
  end

  def test_import_should_not_update_created_at_or_created_on_columns_on_duplicate_keys_by_default
    return unless Topic.supports_on_duplicate_key_update?

    book1 = Book.create :title=>"book1", :author_name=>"Zach", :publisher=>"Pub"
    book2 = Book.create :title=>"book2", :author_name=>"Mark", :publisher=>"Pub"
    book3 = Book.create :title=>"book3", :author_name=>"Zach", :publisher=>"Pub"
    books = [ book1, book2, book3 ]
    created_at_arr = books.inject([]){ |arr,book| arr << book.created_at }
    created_on_arr = books.inject([]){ |arr,book| arr << book.created_on }
    
    Book.import books
    books.each{ |b| b.reload }

    created_at_arr.each_with_index do |time,i|
      assert_equal time.to_s(:db), books[i].created_at.to_s(:db)
    end

    created_on_arr.each_with_index do |time,i|
      assert_equal time.to_s(:db), books[i].created_on.to_s(:db)
    end
  end

  def test_import_should_update_updated_at_or_updated_on_columns_with_duplicate_keys_by_default
    return unless Topic.supports_on_duplicate_key_update?

    book1 = Book.create :title=>"book1", :author_name=>"Zach", :publisher=>"Pub"
    book2 = Book.create :title=>"book2", :author_name=>"Mark", :publisher=>"Pub"
    sleep 2
    books = [ book1, book2 ]
    updated_at_arr = books.inject([]){ |arr,book| arr << book.updated_at }
    updated_on_arr = books.inject([]){ |arr,book| arr << book.updated_on }
    Book.import books
    books.each{ |b| b.reload }

    updated_at_arr.each_with_index do |time,i|
      assert time.to_f < books[i].updated_at.to_f
    end

    updated_on_arr.each_with_index do |time,i|
     assert time.to_f < books[i].updated_on.to_f
    end
  end

  def test_import_without_timestamps
    columns = %W{ id author_name }
    values = []
    values << [ 1, "Jerry Carter" ]
    values << [ 2, "Chad Fowler" ]
    
    expected_count = Topic.count
    Topic.import( columns, values,
      :validate=>false,
      :timestamps=>false )
    
    assert_equal expected_count+values.size, Topic.count, "#{ values.size } new records should have been created!"
    assert_equal Topic.find( 1 ).created_at, nil, "created_at should be nil"
    assert_equal Topic.find( 2 ).updated_at, nil, "updated_at should be nil"
  end

end
