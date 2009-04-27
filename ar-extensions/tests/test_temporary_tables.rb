require File.expand_path(File.join(File.dirname(__FILE__), "test_helper"))

class TestTemporaryTableExtension < TestCaseSuperClass
  def setup
    unless Book.supports_temporary_tables?
      raise "Your database adapter doesn't support temporary tables"
    end
    super
  end

  def test_creating_a_temporary_table_creates_a_model
    model_class = Book.create_temporary_table
    assert_kind_of Book, model_class.allocate
  ensure
    model_class.drop
  end

  def test_creating_a_temporary_table_creates_a_toplevel_namespace_accessible_model
    model_class = Book.create_temporary_table

    assert TempBook
  ensure
    model_class.drop
  end

  def test_model_can_be_dropped
    model_class = Book.create_temporary_table
    model_class.drop

    assert !Object.const_defined?(model_class.name) 
  end

  def test_creating_a_temporary_table_with_predefined_name
    model_class = Book.create_temporary_table :table_name => "xyz"
    assert_equal "xyz", model_class.table_name
  ensure
    model_class.drop
  end

  def test_temp_table_drops_after_block
    temp_model = nil
    Book.create_temporary_table { |t| temp_model = t }
    assert !Object.const_defined?(temp_model.name.to_sym)
  end

  def test_creating_a_temporary_table_with_a_block
    Book.create_temporary_table do |model_clazz|
      model_clazz.create(
        :author_name => "Zach Dennis",
        :title       => "SomeBook",
        :publisher   => "SomePublisher"
      )

      assert_equal 1, model_clazz.count
    end
  end

  def test_creating_a_temporary_table_with_specified_model_name
    Book.create_temporary_table(:model_name => "TestTable") do |t|
      assert_equal t.name, "TestTable"
    end
  end

  def test_creating_a_temporary_table_with_specified_table_name
    Book.create_temporary_table(:table_name => "my_test_books") do |t|
      assert_equal t.table_name, "my_test_books"
    end
  end

  def test_temporary_table_doesnt_persist_across_connections
    model_class = Book.create_temporary_table
    assert_kind_of Book, model_class.allocate
  ensure
    model_class.drop
  end

  def test_permanent_table_persists_across_connections
    model_class = Book.create_temporary_table :permanent => true
    model_class.allocate
    model_class.connection.reconnect!

    assert_equal 0, model_class.count # if we can count, it persisted
  ensure
    model_class.drop
  end
end
