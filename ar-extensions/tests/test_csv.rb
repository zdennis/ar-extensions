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

  def test_find_to_csv_with_only_option_as_symbols
    options = { :only => [ :name, :salary ] }

    developers = Developer.find( :all )
    csv = developers.to_csv( options )

    csv_arr = FasterCSV.parse( csv )
    csv_headers = csv_arr.first
    csv_data_rows = csv_arr[1..-1]

    assert_equal Developer.count, csv_data_rows.size
    assert_equal options[:only].size, csv_headers.size

    developer_csv = Developer.find( :all, :limit=>1 ).to_csv( options )
    assert csv =~ /#{Regexp.escape(developer_csv)}/
  end
  
  def test_find_to_csv_with_only_option_as_strings
    options = { :only => [ 'name', 'salary' ] }
    
    developers = Developer.find( :all )
    csv = developers.to_csv( options )

    csv_arr = FasterCSV.parse( csv )
    csv_headers = csv_arr.first
    csv_data_rows = csv_arr[1..-1]

    assert_equal Developer.count, csv_data_rows.size
    assert_equal options[:only].size, csv_headers.size

    developer_csv = Developer.find( :all, :limit=>1 ).to_csv( options )
    assert csv =~ /#{Regexp.escape(developer_csv)}/
  end
  
  def test_find_to_csv_with_except_option_as_symbols
    options = { :except => [ :id, :salary ] }
    developers = Developer.find( :all )
    csv = developers.to_csv( options )
    
    csv_arr = FasterCSV.parse( csv )
    csv_headers = csv_arr.first
    csv_data_rows = csv_arr[1..-1]
    
    assert_equal Developer.count, csv_data_rows.size
    assert_equal Developer.columns.size - options[:except].size, csv_headers.size
    
    expected_headers = (Developer.columns.map{ |c| c.name } - options[:except].map{|e| e.to_s } )
    assert_block do
      expected_headers.inject( true ) { |bool,header| 
        bool = false unless csv_headers.include?( header  )
        bool }
    end
  end

  def test_find_to_csv_with_except_option_as_strings
    options = { :except => [ 'id', 'salary' ] }
    developers = Developer.find( :all )
    csv = developers.to_csv( options )
    
    csv_arr = FasterCSV.parse( csv )
    csv_headers = csv_arr.first
    csv_data_rows = csv_arr[1..-1]
    
    assert_equal Developer.count, csv_data_rows.size
    assert_equal Developer.columns.size - options[:except].size, csv_headers.size

    expected_headers = (Developer.columns.map{ |c| c.name } - options[:except] )
    assert_block do
      expected_headers.inject( true ) { |bool,header| 
        bool = false unless csv_headers.include?( header  )
        bool }
    end

  end
    
  def test_find_to_csv_should_have_no_header_row
    developers = Developer.find( :all )
    csv = developers.to_csv( :headers => false )
    
    assert_equal Developer.count, FasterCSV.parse( csv ).size    
  end
  
  def test_find_to_csv_should_have_header_row 
    developers = Developer.find( :all )
    csv = developers.to_csv( :headers => true )

    assert_equal Developer.count + 1, FasterCSV.parse( csv ).size
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

