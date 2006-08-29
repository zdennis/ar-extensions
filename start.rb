require 'boot'

config = YAML.load( IO.read( 'config/database.yml' ) )
ActiveRecord::Base.establish_connection( config['development'] )

class Topic < ActiveRecord::Base ; end
class Developer < ActiveRecord::Base ; end

