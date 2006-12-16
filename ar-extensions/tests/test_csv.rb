require File.join( File.dirname( __FILE__ ), 'boot')
require 'fileutils'

class Developer < ActiveRecord::Base
  include ActiveRecord::Extensions::FindToCSV
end

class CSVTest < Test::Unit::TestCase
  fixtures 'developers'

  def teardown
    Developer.delete_all
  end

  def test_find_to_csv
    csv = Developer.find( :all ).to_csv

    csv_arr = FasterCSV.parse( csv )
    csv_headers = csv_arr.first
    csv_data_rows = csv_arr[1..-1]

    assert_equal Developer.count, csv_data_rows.size
    assert_equal Developer.columns.size, csv_headers.size

    assert_block do
      Developer.columns.each do |c|
        break false unless csv_headers.include?( c.name )
      end
    end

    developer_csv = Developer.find( :all, :limit=>1 ).to_csv
    assert csv =~ /#{Regexp.escape(developer_csv)}/
  end

  def test_find_to_csv_with_headers_option_as_symbols
    options = { :headers=>[ :name, :salary ] }
    developers = Developer.find( :all )
    csv = developers.to_csv( options )

    expected_number_of_rows = Developer.count + 1     # plus 1 for header row
    expected_number_of_cols = 2

    csv_arr = FasterCSV.parse( csv )
    csv_headers = csv_arr.first
    csv_data_rows = csv_arr[1..-1]

    assert_equal Developer.count, csv_data_rows.size
    assert_equal options[:headers].size, csv_headers.size

    developer_csv = Developer.find( :all, :limit=>1 ).to_csv( options )
    assert csv =~ /#{Regexp.escape(developer_csv)}/
  end

  def test_find_to_csv_file
    developers = Developer.find( :all )
 
    filename = File.join( File.dirname( __FILE__ ), 'test.csv' )
    developers.to_csv_file( filename )
    assert File.exists?( filename )

    FileUtils.rm( filename )
  end

  def test_find_to_csv_file_with_headers_option
    developers = Developer.find( :all )
 
    filename = File.join( File.dirname( __FILE__ ), 'test.csv' )
    developers.to_csv_file( filename, :headers=>[ :name, :salary ] )
    assert File.exists?( filename )

    FileUtils.rm( filename )
  end
    
end

