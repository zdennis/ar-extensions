require File.join( File.dirname( __FILE__ ), 'boot')
require 'fileutils'

class Developer < ActiveRecord::Base
  include ActiveRecord::Extensions::FindToCSV
end

class CSVTest < Test::Unit::TestCase
  fixtures 'developers'

  def test_find_to_csv
    developers = Developer.find( :all )
 
    filename = File.join( File.dirname( __FILE__ ), 'test.csv' )
    developers.to_csv( filename )
 
    assert File.exists?( filename )

    FileUtils.rm( filename )
  end
    
end

