dir = File.dirname( __FILE__ )

libdir = File.expand_path(File.join(dir, '..', 'lib', 'ar-extensions')) 
require libdir
require 'ar-extensions/csv'

# Load all database adapter specific stuff
Dir[File.join(libdir, "**/#{ENV['ARE_DB']}.rb")].each do |file|
  require file
end