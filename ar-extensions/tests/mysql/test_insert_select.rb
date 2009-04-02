require File.expand_path( File.join( File.dirname( __FILE__ ), '..', 'test_helper' ))

class InsertSelectTest < TestCaseSuperClass
  self.fixtures 'books'
  if ActiveRecord::Base.connection.class.name =~ /sqlite/i
    self.use_transactional_fixtures = false
  end
  
  #define the duplicate key update for mysql for testing
  #add oracle, postgre, sqlite, etc when implemented
  if ENV["ARE_DB"] == 'mysql'
    DUPLICATE_UPDATE_STR = 'cart_items.updated_at=VALUES(`updated_at`), copies=VALUES(copies), book_id=VALUES(`book_id`)'
  else
    DUPLICATE_UPDATE_STR = [:updated_at, :copies, :book_id]
  end
  
  def setup
    @connection = ActiveRecord::Base.connection
    @conditions = ['author_name like :author_name', {:author_name => 'Terry Brooks'}]
    @into_columns = [:book_id, :shopping_cart_id, :copies, :updated_at, :created_at]
    @cart = ShoppingCart.create!(:name => 'My Shopping Cart')
    @time = Time.now - 2.seconds
    
    Topic.destroy_all
    ShoppingCart.destroy_all
  end
  
  def teardown
    Topic.destroy_all
    ShoppingCart.destroy_all
  end
 
  #test simple insert select
  def test_insert_select_should_import_data_from_one_model_into_another
    assert_equal 0, Topic.count

    timestamp = Time.now
    Topic.insert_select(
      :from => :book,
      :select => ['title, author_name, ?', timestamp],
      :into => [:title, :author_name, :updated_at])

    books = Book.find :all, :order => 'title'
    topics = Topic.find :all, :order => 'title'
    
    assert_equal books.length, topics.length
    
    topics.each_with_index {|topic, idx|
      assert_equal topic.author_name, books[idx].author_name
      assert_equal topic.title, books[idx].title
      assert_equal topic.updated_at.to_s, timestamp.to_s
    }
  end

  def test_insert_select_should_import_data_from_one_model_into_another_ignoring_existing_data
    time = Time.now - 4.seconds
    #insert book data into cart
    CartItem.insert_select(
       :from => :book,
       :select => ['books.id, ?, ?, ?, now()', @cart.to_param, 1, time],
       :into => [:book_id, :shopping_cart_id, :copies, :updated_at, :created_at])

    total = CartItem.count(:id, :conditions => ['shopping_cart_id = ? and updated_at = ?', @cart.to_param, time])
    assert_equal 9, total, "Expecting 6 cart items. Instead got #{total}"

    #insert the same data from book into the cart
    CartItem.insert_select(:from => Book,
                           :select => ['books.id, ?, ?, ?, now()', @cart.to_param, 1, Time.now],
                           :into => 'cart_items.book_id, shopping_cart_id, copies, updated_at, created_at',
                           :ignore => true )

    #ensure that the data has not changed
    total = CartItem.count(:id, :conditions => ['shopping_cart_id = ? and updated_at = ?', @cart.to_param, time])
    assert_equal 9, total, "Expecting 6 cart items. Instead got #{total}"
  end
  
  def test_insert_select_should_import_data_from_one_model_into_another_updating_existing_data(options_one={}, options_two={})
    fun_topic = Topic.create!(:title => 'Fun Books', :author_name => 'Big Bird')
    ok_topic = Topic.create!(:title => 'OK Books', :author_name => 'sloth')
    boring_topic = Topic.create!(:title => 'Boring Books', :author_name => 'Giraffe')
    
    Book.update_all(['topic_id = ?', boring_topic])
    Book.update_all(['topic_id = ?', fun_topic], 'books.id <  3')
    Book.update_all(['topic_id = ?', ok_topic], 'books.id =  3')
    
    CartItem.insert_select(
      {:from => :book,
       :select => ['books.id, ?, ?, ?, ?', @cart.to_param, 1, @time, @time],
       :into => @into_columns,
       :conditions => ['topics.title = :title', {:title => 'Fun Books'}],
       :include => :topic }.merge(options_one))
    
    validate_cart_items({:total => 2, :copies => 1 },
                        :conditions => ['topics.title in (?)', ['Fun Books']],
                        :include => { :book => :topic })

    #insert select with on duplicate key update written as a string
    new_time = Time.now
    CartItem.insert_select(
      {:from => :book,
       :select => ['books.id, ?, ?, ?, ?', @cart.to_param, 2, new_time, new_time],
       :into => @into_columns,
       :conditions => ['topics.title in (?)', ['Fun Books', 'OK Books']],
       :include => :topic  , 
       :on_duplicate_key_update => DUPLICATE_UPDATE_STR}.merge(options_two))
      
    # 3 total items
    assert_equal 3, CartItem.count
    
    #2 fun books should have updated the updated_at and copies field
    validate_cart_items({:total => 2, :updated_at => new_time, :copies => 2},
                        :conditions => ['topics.title in (?)', ['Fun Books']],
                        :include => { :book => :topic })
                        
    #1 ok book                    
    validate_cart_items({:total => 1, :updated_at => new_time, :created_at => new_time, :copies => 2},
                        :conditions => ['topics.title in (?)', ['OK Books']],
                        :include => { :book => :topic })                      
  end
  
  def test_insert_select_should_import_data_from_one_model_into_another_updating_existing_data_using_joins_and_limit
    #use a join instead of include
    options = {:include => nil, :joins => 'inner join topics on topics.id = books.topic_id', :limit => 4}
    test_insert_select_should_import_data_from_one_model_into_another_updating_existing_data options, options
  end
  
  #test insert select with ignore and duplicate options
  def test_insert_select_should_import_data_from_one_model_into_another_updating_multiple_columns
    
    @cart_copies = Book.count(:all, :conditions => @conditions)
    assert @cart_copies > 0
    
    @time = Time.now
    CartItem.insert_select(
      :from => :book,
      :select => ['books.id, ?, ?, ?, ?', @cart.to_param, 1, @time, @time], 
      :conditions => @conditions,
      :into => @into_columns)
    
    validate_cart_items :total => @cart_copies, :copies => 1

    #use on duplicate update
    #this means that the book count should change to 2 and the updated time should be changed to new_time
    new_time = Time.now
    CartItem.insert_select( 
       :from => :book,
       :select => ['books.id, :cart, :copies, :updated_at, :created_at', {:copies => 2, :cart => @cart, :created_at => new_time, :updated_at => new_time}],
       :conditions => @conditions, 
       :into => @into_columns,
       :on_duplicate_key_update => [:updated_at, :copies])

    validate_cart_items :total => @cart_copies, :updated_at => new_time, :copies => 2
  end
  
  protected
  
  def validate_cart_items(expected_values = {}, find_options = {})
    
    vals = {:shopping_cart_id => @cart.to_param, :updated_at => @time, :created_at => @time, :copies => 1}.merge expected_values
    total_count = vals.delete(:total)
    
    items = CartItem.find(:all, find_options)
    assert_equal(total_count, items.length, "Expecting #{total_count}, recieved #{items.length}") unless total_count.nil?
    
    items.each do |item|
      vals.each do |method, val|
        actual = item.send method
        assert_equal val.to_s, actual.to_s, "Expecting #{method} = #{val}. Instead got #{actual}"
      end
    end
  end
end

