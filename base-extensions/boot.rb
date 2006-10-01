begin ; require 'rubygems' rescue LoadError; end
require 'active_record' # ActiveRecord loads the Benchmark library automatically

require File.join( File.dirname( __FILE__ ), 'init.rb' )
