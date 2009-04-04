require 'ostruct'
begin ; require 'active_record' ; rescue LoadError; require 'rubygems'; require 'active_record'; end

$LOAD_PATH.unshift File.expand_path(File.join(File.dirname(__FILE__), 'lib'))

require 'ar-extensions/util/support_methods'
require 'ar-extensions/util/sql_generation'
require 'ar-extensions/version'
require 'ar-extensions/delete'
require 'ar-extensions/extensions'
require 'ar-extensions/create_and_update'
require 'ar-extensions/finder_options'
require 'ar-extensions/foreign_keys'
require 'ar-extensions/fulltext'
require 'ar-extensions/import'
require 'ar-extensions/insert_select'
require 'ar-extensions/finders'
require 'ar-extensions/synchronize'
require 'ar-extensions/temporary_table'
require 'ar-extensions/union'
require 'ar-extensions/adapters/abstract_adapter'

#load all available functionality for specified adapter
# Ex. ENV['LOAD_ADAPTER_EXTENSIONS'] = 'mysql'
if ENV['LOAD_ADAPTER_EXTENSIONS']
  require "active_record/connection_adapters/#{ENV['LOAD_ADAPTER_EXTENSIONS']}_adapter.rb"
  file_regexp = File.join(File.dirname(__FILE__), 'lib', 'ar-extensions','**',
                          "#{ENV['LOAD_ADAPTER_EXTENSIONS']}.rb")
                        
  Dir.glob(file_regexp){|file| require(file) }
end
