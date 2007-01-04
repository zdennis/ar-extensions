require File.join( File.dirname( __FILE__ ), 'boot')
require 'fileutils'
require 'fastercsv'

class Developer < ActiveRecord::Base
  include ActiveRecord::Extensions::FindToCSV
end

class Address < ActiveRecord::Base
  include ActiveRecord::Extensions::FindToCSV
end

class CSVTest < Test::Unit::TestCase
  fixtures 'developers', 'addresses'

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

  def test_find_to_csv_file_verify_data_rows
    developers = Developer.find( :all )
 
    filename = File.join( File.dirname( __FILE__ ), 'test.csv' )
    developers.to_csv_file( filename )

    csv_arr = FasterCSV.parse( IO.read( filename ) )
    csv_data_rows = csv_arr[1..-1]
    assert_equal Developer.count, csv_data_rows.size

    FileUtils.rm( filename )
  end

  def test_find_to_csv_file_verify_implicit_headers
    developers = Developer.find( :all )
 
    filename = File.join( File.dirname( __FILE__ ), 'test.csv' )
    developers.to_csv_file( filename )
    assert File.exists?( filename )

    csv_arr = FasterCSV.parse( IO.read( filename ) )
    csv_headers = csv_arr.first
    assert_equal Developer.columns.size, csv_headers.size

    FileUtils.rm( filename )
  end

  def test_find_to_csv_file_verify_explicit_headers
    developers = Developer.find( :all )
 
    filename = File.join( File.dirname( __FILE__ ), 'test.csv' )
    developers.to_csv_file( filename, :headers=>true )
    assert File.exists?( filename )

    csv_arr = FasterCSV.parse( IO.read( filename ) )
    csv_headers = csv_arr.first
    assert_equal Developer.columns.size, csv_headers.size

    FileUtils.rm( filename )
  end


  def test_find_to_csv_headers_with_include_option_as_array_for_a_belongs_to_association
    csv = Address.find( :all ).to_csv( :include => [ :developer ] )
    csv_arr = FasterCSV.parse( csv )
    csv_headers = csv_arr.first

    assert_equal Address.columns.size + Developer.columns.size, csv_headers.size

    expected_headers = Address.columns_hash.keys + Developer.columns.map{ |c| "developer[#{c.name}]" }
    assert_block do
      expected_headers.inject( false ) { |bool,header| 
        true if csv_headers.include?( header  ) }
    end
  end

  def test_find_to_csv_headers_with_include_option_as_hash_with_only_option_for_a_belongs_to_association
    association_columns = [ :name ]
    csv = Address.find( :all ).to_csv( :include => { :developer=>{ :only=>association_columns } } )
    csv_arr = FasterCSV.parse( csv )
    csv_headers = csv_arr.first

    assert_equal Address.columns.size + association_columns.size, csv_headers.size

    expected_headers = Address.columns_hash.keys + association_columns.map{ |column| "developer[#{column}]" }
    assert_block do
      expected_headers.inject( false ) { |bool,header| 
        true if csv_headers.include?( header  ) }
    end
  end

  def test_find_to_csv_headers_with_include_option_as_hash_with_except_option_for_a_belongs_to_association
    association_columns = [ :name ]
    csv = Address.find( :all ).to_csv( :include => { :developer=>{ :except=>association_columns } } )
    csv_arr = FasterCSV.parse( csv )
    csv_headers = csv_arr.first

    developer_headers = Developer.columns_hash.keys - association_columns
puts developer_headers.inspect
puts developer_headers.size
puts Address.columns.size
puts '**', csv_headers.inspect
    assert_equal Address.columns.size + developer_headers.size, csv_headers.size

    expected_headers = Address.columns_hash.keys + developer_headers.map{ |column| "developer[#{column}]" }
    assert_block do
      expected_headers.inject( false ) { |bool,header| 
        true if csv_headers.include?( header  ) }
    end
  end


  def test_find_to_csv_data_rows_with_include_option_for_a_belongs_to_association
    csv = Address.find( :all ).to_csv( :include => [ :developer ] )
    csv_arr = FasterCSV.parse( csv )
    csv_data_rows = csv_arr[1..-1]

    assert_equal Address.count, csv_data_rows.size
  end

  
end

__END__
    csv = Address.find( :all ).to_csv( :include => [ :developer ] )
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


addresses.to_csv( :include=>[ :developer ] )

addresses.to_csv( :include=>{ :developer=>[ :name ] } )

addresses.to_csv( :include=>{ :developer=>[ :name ] },
                  :order => :alphabetically )

addresses.to_csv( :include=>{ :developer=>[ :name ] },
                  :order => proc { |a,b| a <=> b } )

addresses.to_csv( :headers => { :id=>"ID" },
                  :developer_headers => { :name => "My Name" },
                  :include=>{ :developer=>[ :name ] } )
              
