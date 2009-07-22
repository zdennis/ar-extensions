require 'rake'

Gem::Specification.new do |s|
  s.name = %q{ar-extensions}
  s.version = "0.9.2"
  s.date = %q{2009-04-20}
  s.summary = %q{Extends ActiveRecord functionality.}
  s.email = %q{zach.dennis@gmail.com}
  s.homepage = %q{http://www.continuousthinking.com/tags/arext}
  s.rubyforge_project = %q{arext}
  s.description = %q{Extends ActiveRecord functionality by adding better finder/query support, as well as supporting mass data import, foreign key, CSV and temporary tables}
  s.require_path = 'lib'
  s.has_rdoc = true
  s.authors = ["Zach Dennis", "Mark Van Holstyn", "Blythe Dunham"]
  s.files = FileList[ 'init.rb', 'db/**/*', 'Rakefile', 'ChangeLog', 'README', 'config/**/*', 'lib/**/*.rb', 'test/**/*' ]
  s.rdoc_options = ["--main", "README"]
  s.extra_rdoc_files = ["README"]
  s.add_dependency(%q<activerecord>, [">= 2.1.2"])
end
