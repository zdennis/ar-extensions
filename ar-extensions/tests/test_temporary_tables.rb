require File.expand_path( File.join( File.dirname( __FILE__ ), 'boot' ) )

class TemporaryTableCRUDTest < Test::Unit::TestCase
#  self.fixture_path = File.join( File.dirname( __FILE__ ), 'fixtures/unit/temporary_table' )

  def test_creating_a_temporary_table_creates_a_model
    unless Book.supports_temporary_tables?
      STDERR.puts "test_creating_a_temporary_table_creates_a_model is not testing, since your database adapter doesn't support temporary tables."
    else    
      model_class = Book.create_temporary_table
      assert_kind_of ActiveRecord::TemporaryTable, model_class.allocate
      model_class.drop
    end
  end
 
  def test_creating_a_temporary_table_creates_a_toplevel_namespace_accessible_model
    unless Book.supports_temporary_tables?
      STDERR.puts "test_creating_a_temporary_table_creates_a_toplevel_namespace_accessible_model is not testing, since your database adapter doesn't support temporary tables."
    else    
      model_class = Book.create_temporary_table
      assert TempBook
      model_class.drop
    end
  end

  def test_model_can_be_dropped
    unless Book.supports_temporary_tables?
      STDERR.puts "test_model_can_be_dropped is not testing, since your database adapter doesn't support temporary tables."
    else        
      model_class = Book.create_temporary_table
      model_class.drop
      assert !Object.const_defined?( model_class.name) 
    end
  end

  def test_creating_a_temporary_table_with_predefined_name
    unless Book.supports_temporary_tables?
      STDERR.puts "test_creating_a_temporary_table_with_predefined_name is not testing, since your database adapter doesn't support temporary tables."
    else        
      model_class = Book.create_temporary_table :table_name=>'xyz'
      assert_equal 'xyz', model_class.table_name
      model_class.drop
      assert !Object.const_defined?( model_class.name )
    end
  end

  def test_creating_a_temporary_table_with_a_block
    unless Book.supports_temporary_tables?
      STDERR.puts "test_creating_a_temporary_table_with_a_block is not testing, since your database adapter doesn't support temporary tables."
    else        
      model_name = ''
      Book.create_temporary_table do |model_clazz|
        model_name = model_clazz.name
        rec = model_clazz.create :author_name=>"Zach Dennis"
        assert_equal 1, model_clazz.count
      end
      assert !Object.const_defined?( model_name )
    end
  end

  def test_creating_a_temporary_table_with_specified_model_and_table_names
    unless Book.supports_temporary_tables?
      STDERR.puts "test_creating_a_temporary_table_with_specified_model_and_table_names is not testing, since your database adapter doesn't support temporary tables."
    else
      model_name, table_name = 'TestTable', 'some_table'
      model_class = Book.create_temporary_table :model_name=>model_name, :table_name=>table_name
      assert_equal model_name, model_class.name
      assert_equal table_name, model_class.table_name
    end
  end

  def test_temporary_table_doesnt_persist_across_connections
    unless Book.supports_temporary_tables?
      STDERR.puts "test_temporary_table_doesnt_persist_across_connections is not testing, since your database adapter doesn't support temporary tables."
    else
      model_class = Book.create_temporary_table
      assert_kind_of ActiveRecord::TemporaryTable, model_class.allocate
      
      model_class.connection.reconnect!
      assert_raises( ActiveRecord::StatementInvalid ){ model_class.count }
    end
  end

end


class LikeTableCRUDTest < Test::Unit::TestCase
#  self.fixture_path = File.join( File.dirname( __FILE__ ), 'fixtures/unit/temporary_table' )

  def test_creating_like_table
    unless Book.supports_temporary_tables?
      STDERR.puts "test_creating_like_table isn't testing, since your database adapter doesn't support temporary tables."
    else
      model_class = Book.create_temporary_table :permanent=>true
      assert_kind_of ActiveRecord::TemporaryTable, model_class.allocate
      model_class.drop
    end
  end

  def test_permanent_table_persists_across_connections
    unless Book.supports_temporary_tables?
      STDERR.puts "test_permanent_table_persists_across_connections is not testing, since your database adapter doesn't support temporary tables."
    else
      model_class = Book.create_temporary_table :permanent=>true
      assert_kind_of ActiveRecord::TemporaryTable, model_class.allocate
      
      model_class.connection.reconnect!
      assert_equal 0, model_class.count
      
      model_class.drop    
      assert !Object.const_defined?( model_class.name) 
    end
  end


end
