require File.expand_path( File.join( File.dirname( __FILE__ ), '..', 'test_helper' ) )

class OracleAdapterTest< TestCaseSuperClass
  
  def setup
    @target = ActiveRecord::ConnectionAdapters::OracleAdapter.allocate
  end
  
  def test_should_generate_the_correct_next_value_for_sequence
    result = @target.next_value_for_sequence("blah")
    assert_equal 'blah.nextval', result, "wrong next value sequence identifier"
  end
  
end