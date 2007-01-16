require File.expand_path( File.join( File.dirname( __FILE__ ), 'boot' ) )

class TestToCSVHeaders < Test::Unit::TestCase
  self.fixture_path = File.join( File.dirname( __FILE__ ), 'fixtures/unit/to_csv_headers' )
  self.fixtures 'developers', 'addresses'

  def test_to_csv_headers_verify_order_and_names_with_default_options
    headers = Developer.to_csv_headers
    assert headers
    assert_equal  Developer.columns.size, headers.size
    assert_equal Developer.columns.map{ |c| c.name }.sort, headers
  end

  def test_to_csv_headers_verify_order_and_names_with_headers_option_as_true
    headers = Developer.to_csv_headers( :headers=> true )
    assert headers
    assert_equal  Developer.columns.size, headers.size
    assert_equal Developer.columns.map{ |c| c.name }.sort, headers
  end

  def test_to_csv_headers_verify_order_and_names_with_headers_option_as_false
    headers = Developer.to_csv_headers( :headers=>false )
    assert headers.nil?
  end

  def test_to_csv_headers_verify_order_and_names_with_headers_option_as_array_of_symbols
    wanted_headers = [ :id, :name ]
    headers = Developer.to_csv_headers( :headers=>wanted_headers )
    assert headers
    assert_equal wanted_headers.size, headers.size
    
    expected_headers = Developer.columns.select{ |c| wanted_headers.include?( c.name.to_sym ) }.map{ |c| c.name }
    assert_equal expected_headers, headers
  end

    def test_to_csv_headers_verify_order_and_names_with_headers_option_as_array_of_symbols
    wanted_headers = [ :id, :name ]
    headers = Developer.to_csv_headers( :headers=>wanted_headers )
    assert headers
    assert_equal wanted_headers.size, headers.size
    
    expected_headers = Developer.columns.select{ |c| wanted_headers.include?( c.name.to_sym ) }.map{ |c| c.name }
    assert_equal expected_headers, headers
  end
  
  def test_to_csv_headers_with_nonalphabetical_list_array_of_strings
    headers = Developer.to_csv_headers( :headers=>%W( name id ) )
    assert headers
    assert_equal 2, headers.size
    
    expected_headers = %W( name id )
    assert_equal expected_headers, headers
  end

  def test_to_csv_headers_verify_order_and_names_with_include_option_as_array_of_symbols
    headers = Address.to_csv_headers( :include=>[ :developer ] )
    assert headers
    assert_equal Address.columns.size + Developer.columns.size, headers.size

    expected_headers = Address.columns.map{ |c| c.name }.sort + Developer.columns.map{ |c| "developer[#{c.name}]" }.sort
    assert_equal expected_headers, headers
  end

  def test_to_csv_headers_verify_order_and_names_with_include_option_as_empty_hash
    headers = Address.to_csv_headers( :include=>{ :developer=>{} } )
    assert headers
    assert_equal Address.columns.size + Developer.columns.size, headers.size

    expected_headers = Address.columns.map{ |c| c.name }.sort + Developer.columns.map{ |c| "developer[#{c.name}]" }.sort
    assert_equal expected_headers, headers
  end

  def test_to_csv_headers_for_a_belongs_to_association_with_options_as_array_of_symbols
    developer_headers = [ :id, :name ]
    headers = Address.to_csv_headers( :include=>{ :developer=>{ :headers=>developer_headers } } )
    assert headers
    assert_equal Address.columns.size + developer_headers.size, headers.size

    expected_headers = Address.columns.map{ |c| c.name }.sort + developer_headers.map{ |hdr| "developer[#{hdr}]" }.sort
    assert_equal expected_headers, headers
  end

  def test_to_csv_headers_for_a_belongs_to_association_with_options_as_array_of_strings
    developer_headers = [ 'id', 'name' ]
    headers = Address.to_csv_headers( :include=>{ :developer=>{ :headers=>developer_headers } } )
    assert headers
    assert_equal Address.columns.size + developer_headers.size, headers.size

    expected_headers = Address.columns.map{ |c| c.name }.sort + developer_headers.map{ |hdr| "developer[#{hdr}]" }.sort
    assert_equal expected_headers, headers
  end

  def test_to_csv_headers_for_a_belongs_to_association_with_specified_columns_as_symbols
    developer_columns = [ :id, :name ]
    headers = Address.to_csv_headers( :include => { :developer=>{ :only=>developer_columns } } )

    assert_equal Address.columns.size + developer_columns.size, headers.size

    expected_headers = Address.columns_hash.keys + developer_columns.map{ |column| "developer[#{column}]" }
    expected_headers.each do |header|
      assert headers.include?( header ), "The expected header '#{header}' is missing!"
    end
  end

  def test_to_csv_headers_for_a_belongs_to_association_with_specified_columns_as_symbols2
    headers = Address.to_csv_headers( :only=>[ :city, :state ],
                                      :include => { :developer=>{ :only=>[ :id, :name ] } } )

    assert_equal 4, headers.size

    expected_headers = %W( city state developer[id] developer[name] )
    expected_headers.each do |header|
      assert headers.include?( header ), "The expected header '#{header}' is missing!"
    end
  end
  
  
  def test_to_csv_headers_for_a_belongs_to_association_with_specified_columns_as_strings
    developer_columns = [ 'id', 'name' ]
    headers = Address.to_csv_headers( :include => { :developer=>{ :only=>developer_columns } } )

    assert_equal Address.columns.size + developer_columns.size, headers.size

    expected_headers = Address.columns_hash.keys + developer_columns.map{ |column| "developer[#{column}]" }
    expected_headers.each do |header|
      assert headers.include?( header ), "The expected header '#{header}' is missing!"
    end
  end

  def test_to_csv_headers_for_a_belongs_to_association_with_excluded_columns_as_symbols
    excluded_columns = [ :id, :name ]
    headers = Address.to_csv_headers( :include => { :developer=>{ :except=>excluded_columns } } )
    assert_equal Address.columns.size + Developer.columns.size - excluded_columns.size, headers.size

    developer_columns = Developer.columns.map{ |c| c.name.to_sym } - excluded_columns
    expected_headers = Address.columns_hash.keys + developer_columns.map{ |column| "developer[#{column}]" }
    expected_headers.each do |header|
      assert headers.include?( header ), "The expected header '#{header}' is missing!"
    end
  end

  def test_to_csv_headers_for_a_belongs_to_association_with_excluded_columns_as_strings
    excluded_columns = [ 'id', 'name' ]
    headers = Address.to_csv_headers( :include => { :developer=>{ :except=>excluded_columns } } )
    assert_equal Address.columns.size + Developer.columns.size - excluded_columns.size, headers.size

    developer_columns = Developer.columns.map{ |c| c.name.to_s } - excluded_columns
    expected_headers = Address.columns_hash.keys + developer_columns.map{ |column| "developer[#{column}]" }
    expected_headers.each do |header|
      assert headers.include?( header ), "The expected header '#{header}' is missing!"
    end
  end

  def test_to_csv_header_verify_custom_headers_with_headers_as_hash
    headers = Address.to_csv_headers( :headers=>{ :city=>"City1", :state=>"State1", :zip=>"Zip1" } )
    assert_equal 3, headers.size
    [ "City1", "State1", "Zip1" ].each{ |e| assert headers.include?( e ), "Missing expected header '#{e}'!" }
  end

  def test_to_csv_header_for_a_belongs_to_association_verify_custom_headers_with_headers_as_hash
    developer_headers = { :name=>"DeveloperName", :salary=>"DeveloperSalary" }
    headers = Address.to_csv_headers( :include=>{ :developer=>{ :headers=>developer_headers } } )
    assert_equal Address.columns.size + developer_headers.size, headers.size
    [ "DeveloperName" ].each{ |e| assert headers.include?( e ), "Missing expected header '#{e}'!" }
  end

  def test_to_csv_header_for_a_belongs_to_association_verify_custom_headers_with_headers_as_hash2
    primary_headers = { :city=>"CTY", :state=>"ST" }
    developer_headers = { :name=>"DeveloperName", :salary=>"DeveloperSalary" }
    headers = Address.to_csv_headers( :headers=>primary_headers, :include=>{ :developer=>{ :headers=>developer_headers } } )
    assert_equal primary_headers.size + developer_headers.size, headers.size
    [ "DeveloperName" ].each{ |e| assert headers.include?( e ), "Missing expected header '#{e}'!" }
  end


  def test_to_csv_fields_with_default_options
    assert_equal %W( created_at id name salary team_id updated_at ), Developer.to_csv_fields.fields
  end
  
  def test_to_csv_fields_with_headers_option_as_true
    fieldmap = Developer.to_csv_fields( :headers=>true )
    assert_equal %W( created_at id name salary team_id updated_at ), fieldmap.fields
  end

  def test_to_csv_fields_with_headers_option_as_false
    fieldmap = Developer.to_csv_fields( :headers=>true )
    assert_equal %W( created_at id name salary team_id updated_at ), fieldmap.fields
  end
  
  def test_to_csv_fields_with_headers_option_as_array_of_strings
    fieldmap = Developer.to_csv_fields( :headers=>[ 'name', 'id' ] )
    assert_equal %W( name id ), fieldmap.fields
  end

  def test_to_csv_fields_with_headers_option_as_array_of_symbols
    fieldmap = Developer.to_csv_fields( :headers=>[ :name, :id ] )
    assert_equal %W( name id ), fieldmap.fields
  end
  
end

