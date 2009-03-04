require File.expand_path( File.join( File.dirname( __FILE__ ), 'test_helper') )

class InsertSelectTest < Test::Unit::TestCase
  self.fixtures 'books'
  if ActiveRecord::Base.connection.class.name =~ /sqlite/i
    self.use_transactional_fixtures = false
  end
  
  #define the duplicate key update for mysql for testing
  #add oracle, postgre, sqlite, etc when implemented
  if ENV["ARE_DB"] = 'mysql'
    DUPLICATE_UPDATE_STR = 'cart_items.updated_at=VALUES(`updated_at`), copies=VALUES(copies), book_id=VALUES(`book_id`)'
  else
    DUPLICATE_UPDATE_STR = [:updated_at, :copies, :book_id]
  end
  
  def setup
    @connection = ActiveRecord::Base.connection
    @conditions = ['author_name like :author_name', {:author_name => 'Terry Brooks'}]
    @select_columns = [:book_id, :shopping_cart_id, :copies, :updated_at, :created_at]
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
  def test_insert_select_simple
    assert_equal 0, Topic.count

    timestamp = Time.now
    Topic.insert_select :book, {:select => ['title, author_name, ?', timestamp]}, {:select => [:title, :author_name, :updated_at]}

    books = Book.find :all, :order => 'title'
    topics = Topic.find :all, :order => 'title'
    
    assert_equal books.length, topics.length
    
    topics.each_with_index {|topic, idx|
      assert_equal topic.author_name, books[idx].author_name
      assert_equal topic.title, books[idx].title
      assert_equal topic.updated_at.to_s, timestamp.to_s
    }
    
    CartItem.insert_select(:book, 
      {:select => ['books.id, ?, ?, ?, now()', @cart.to_param, 1, Time.now]}, 
      {:select => [:book_id, :shopping_cart_id, :copies, :updated_at, :created_at]})
         CartItem.insert_select(Book, 
                             {:select => ['books.id, ?, ?, ?, now()', @cart.to_param, 1, Time.now]}, 
                            {:select => 'cart_items.book_id, shopping_cart_id, copies, updated_at, created_at',
                             :ignore => true }) 
  end
  
  def test_insert_select_with_include(select_options={})
    
    fun_topic = Topic.create!(:title => 'Fun Books', :author_name => 'Big Bird')
    ok_topic = Topic.create!(:title => 'OK Books', :author_name => 'sloth')
    boring_topic = Topic.create!(:title => 'Boring Books', :author_name => 'Giraffe')
    
    Book.update_all(['topic_id = ?', boring_topic])
    Book.update_all(['topic_id = ?', fun_topic], 'books.id <  3')
    Book.update_all(['topic_id = ?', ok_topic], 'books.id =  3')
    
    CartItem.insert_select(:book, 
      {:select => ['books.id, ?, ?, ?, ?', @cart.to_param, 1, @time, @time], 
       :conditions => ['topics.title = :title', {:title => 'Fun Books'}],
       :include => :topic }.merge(select_options), 
      {:select => @select_columns})
    
    validate_cart_items({:total => 2, :copies => 1 },
                        :conditions => ['topics.title in (?)', ['Fun Books']],
                        :include => { :book => :topic })

    #insert select with on duplicate key update written as a string
    new_time = Time.now
    CartItem.insert_select(:book, 
      {:select => ['books.id, ?, ?, ?, ?', @cart.to_param, 2, new_time, new_time], 
       :conditions => ['topics.title in (?)', ['Fun Books', 'OK Books']],
       :include => :topic  }.merge(select_options), 
      {:select => @select_columns, :on_duplicate_key_update => DUPLICATE_UPDATE_STR})
      
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
  
  def test_insert_select_with_joins_and_limit
    #use a join instead of include
    test_insert_select_with_include :include => nil, :joins => 'inner join topics on topics.id = books.topic_id', :limit => 4
  end
  
  #test insert select with ignore and duplicate options
  def test_insert_select_with_duplicate
    
    @cart_copies = Book.count(:all, :conditions => @conditions)
    assert @cart_copies > 0
    
    @time = Time.now
    CartItem.insert_select(:book, 
      {:select => ['books.id, ?, ?, ?, ?', @cart.to_param, 1, @time, @time], 
       :conditions => @conditions }, 
      {:select => @select_columns})
    
    validate_cart_items :total => @cart_copies, :copies => 1

    #use on duplicate update
    #this means that the book count should change to 2 and the updated time should be changed to new_time
    new_time = Time.now
    CartItem.insert_select(:book, 
      {:select => ['books.id, :cart, :copies, :updated_at, :created_at', {:copies => 2, :cart => @cart, :created_at => new_time, :updated_at => new_time}], 
       :conditions => @conditions }, 
      {:select => @select_columns, 
       :on_duplicate_key_update => [:updated_at, :copies]}) 
    validate_cart_items :total => @cart_copies, :updated_at => new_time, :copies => 2

    #ignore all the duplicates
    #this means that nothing should change
    CartItem.insert_select(:book, 
      {:select => "books.id, #{@cart.to_param}, 3, '#{Time.now.to_s(:db)}', '#{Time.now.to_s(:db)}'",
       :conditions => @conditions }, 
      {:select => @select_columns, 
       :ignore => true})
     
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

