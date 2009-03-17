class MysqlAdapterTest< TestCaseSuperClass
  include ActiveRecord::ConnectionAdapters
  
  def setup
    @connection = ActiveRecord::Base.connection
  end

  def test_get_insert_value_sets
    values = [
      "('1','2','3')",
      "('4','5','6')",
      "('7','8','9')" ]
      
    values_size_in_bytes = MysqlAdapter.sum_sizes( *values )
    base_sql_size_in_bytes = 15
    max_bytes = 30
    
    value_sets = MysqlAdapter.get_insert_value_sets( values, base_sql_size_in_bytes, max_bytes )
    assert_equal 3, value_sets.size, 'Three value sets were expected!'
     
    # Each element in the value_sets array must be an array
    value_sets.each_with_index { |e,i| 
      assert_kind_of Array, e, "Element #{i} was expected to be an Array!" }

    # Each element in the values array should have a 1:1 correlation to the elements
    # in the returned value_sets arrays
    assert_equal values[0], value_sets[0].first
    assert_equal values[1], value_sets[1].first
    assert_equal values[2], value_sets[2].first
  end
  
  def test_insert_many
    base_sql = "INSERT INTO #{Topic.table_name} (`title`,`author_name`) VALUES "
    values = [ 
      "('Morgawr','Brooks, Terry')",
      "('Antrax', 'Brooks, Terry')",
      "('Jarka Ruus', 'Brooks, Terry')" ]

    expected_count = Topic.count + values.size
    @connection.insert_many( base_sql, values )
    assert_equal expected_count, Topic.count, "Incorrect number of records in the database!"    
    Topic.destroy_all
  end
  
end
