require File.expand_path( File.join( File.dirname( __FILE__ ), 'boot') )
require 'fileutils'
require 'fastercsv'

class TestToCSVWithDefaultOptions < Test::Unit::TestCase
  self.fixture_path = File.join( File.dirname( __FILE__ ), 'fixtures/unit/to_csv_with_default_options' )

  def setup
    self.class.fixtures 'developers'
    @csv = Developer.find( 1 ).to_csv
    assert @csv
  end
  
  def teardown
    Developer.delete_all
  end

  def test_find_to_csv_with_default_options_verify_headers
    parsed_csv = FasterCSV.parse( @csv )
    actual_headers = parsed_csv.first
    
    expected_headers = %w( created_at id name salary team_id updated_at )
    assert_equal expected_headers, actual_headers
  end

  def test_find_to_csv_with_default_options_verify_data
    parsed_csv = FasterCSV.parse( @csv )
    actual_data = parsed_csv.last
    
    expected_data = '', '1', 'Zach Dennis', '1', '1', ''
    assert_equal expected_data, actual_data
  end
  
end
