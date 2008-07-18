require 'ostruct'
begin ; require 'active_record' ; rescue LoadError; require 'rubygems'; require 'active_record'; end

$LOAD_PATH.unshift File.expand_path(File.join(File.dirname(__FILE__), 'lib'))
require 'ar-extensions/version'
require 'ar-extensions/extensions'
require 'ar-extensions/foreign_keys'
require 'ar-extensions/fulltext'
require 'ar-extensions/import'
require 'ar-extensions/finders'
require 'ar-extensions/synchronize'
require 'ar-extensions/temporary_table'
require 'ar-extensions/adapters/abstract_adapter'
