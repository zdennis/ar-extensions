require "pathname"
require "rubygems"
require "rake"
require "rake/testtask"

DIR      = Pathname.new(File.dirname(__FILE__))
ADAPTERS = %w(mysql postgresql sqlite sqlite3 oracle)

task :default => ["test:mysql"]

task :boot do 
  require DIR.join("lib", "ar-extensions").expand_path
  require DIR.join("db", "migrate", "version").expand_path
end

ADAPTERS.each do |adapter|
  namespace :db do
    namespace :test do
      desc "Builds test database for #{adapter}"
      task "prepare_#{adapter}" do
        ruby "#{DIR.join('tests', 'prepare.rb')} #{adapter}"
      end
    end
  end

  namespace :test do
    desc "Test base extensions for #{adapter}"
    task(adapter) do
      ENV["ARE_DB"] = adapter
      Rake::Task["db:test:prepare_#{adapter}"].invoke
      ruby "#{DIR.join('tests', 'run.rb')} #{adapter}" 
    end
  end
  
  namespace :activerecord do
    desc "Runs ActiveRecord unit tests for #{adapter} with ActiveRecord::Extensions"
    task(adapter) do
      activerecord_dir = ARGV[1]
      if activerecord_dir.nil? || !File.directory?(activerecord_dir)
        puts "ERROR: Pass in the path to ActiveRecord. Eg: /home/zdennis/rails_trunk/activerecord"
        exit
      end
      
      old_dir, old_env = Dir.pwd, ENV["RUBYOPT"]
      Dir.chdir(activerecord_dir)
      ENV["RUBYOPT"] = "-r#{File.join(old_dir,'init.rb')}"

      load "Rakefile"

      Rake::Task["test_#{adapter}"].invoke
      Dir.chdir(old_dir)
      ENV["RUBYOPT"] = old_env
    end      

    desc "Runs ActiveRecord unit tests for #{adapter} with ActiveRecord::Extensions with ALL available #{adapter} functionality"
    task "#{adapter}_all" do
      ENV["LOAD_ADAPTER_EXTENSIONS"] = adapter
      Rake::Task["test:activerecord:#{adapter}"].invoke
    end
  end    
end
