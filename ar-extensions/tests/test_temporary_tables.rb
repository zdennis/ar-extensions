require File.expand_path(File.join(File.dirname(__FILE__), "test_helper"))

class TestTemporaryTableExtension < TestCaseSuperClass
  def self.test(description, &blk)
    if Book.supports_temporary_tables?
      define_method("test_#{description}", &blk)
    else
      puts "*** no db support for temporary tables, test not running: #{description}"
    end
  end

  test "creating a temporary model creates a model" do
    begin
      model_class = Book.create_temporary_table
      assert_kind_of Book, model_class.allocate
    ensure
      model_class.drop
    end
  end
  
  test "creating_a_temporary_table_creates_a_toplevel_namespace_accessible_model" do
    begin
      model_class = Book.create_temporary_table
      assert TempBook
    ensure
      model_class.drop
    end
  end
  
  test "model can be dropped" do
    model_class = Book.create_temporary_table
    model_class.drop
    assert !Object.const_defined?(model_class.name) 
  end
  
  test "creating_a_temporary_table_with_predefined_name" do
    begin
      model_class = Book.create_temporary_table :table_name => "xyz"
      assert_equal "xyz", model_class.table_name
    ensure
      model_class.drop
    end
  end
  
  test "temporary table drops after block" do
    temp_model = nil
    Book.create_temporary_table { |t| temp_model = t }
    assert !Object.const_defined?(temp_model.name.to_sym)
  end
  
  test "creating a temporary table with a block" do
    Book.create_temporary_table do |model_clazz|
      model_clazz.create(
        :author_name => "Zach Dennis",
        :title       => "SomeBook",
        :publisher   => "SomePublisher"
      )
      assert_equal 1, model_clazz.count
    end
  end
  
  test "creating a temporary table with a specified model name" do
    Book.create_temporary_table(:model_name => "TestTable") do |t|
      assert_equal t.name, "TestTable"
    end
  end
  
  test "creating a temporary table with specified table name" do
    Book.create_temporary_table(:table_name => "my_test_books") do |t|
      assert_equal t.table_name, "my_test_books"
    end
  end
  
  test "temporary table doesn't persist across connections" do
    begin
      model_class = Book.create_temporary_table
      assert_kind_of Book, model_class.allocate
    ensure
      model_class.drop
    end
  end
  
  test "permant table persists across connections" do
    begin
      model_class = Book.create_temporary_table :permanent => true
      model_class.allocate
      model_class.connection.reconnect!
      assert_equal 0, model_class.count # if we can count, it persisted
    ensure
      model_class.drop
    end
  end
end
