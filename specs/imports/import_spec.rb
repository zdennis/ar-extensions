require File.expand_path(File.dirname(__FILE__)) + "/../spec_helper"
require "annex/import/active_record"

describe ActiveRecord, "importing data" do
  before(:each) do
    ActiveRecord::Base.connection.begin_db_transaction
  end
  
  after(:each) do
    ActiveRecord::Base.connection.rollback_db_transaction
  end
  
  it "should import data with array of columns and values" do
    lambda { 
      Topic.import(%w(title author_name), [%w(Ruby Matz), %w(Lisp McCarthy)], :validate => true)
    }.should change(Topic, :count).by(2)
    Topic.find_by_title_and_author_name!('Ruby', 'Matz').should_not be_nil
    Topic.find_by_title_and_author_name!('Lisp', 'McCarthy').should_not be_nil
  end
    
  it "should not import any data when validation fails on at least one record with validations turned on" do
    lambda { 
      result = Topic.import(%w(title author_name), [%w(Ruby Matz), %w(Lisp)], :validate => true)
      result.num_inserts.should == 0
    }.should_not change(Topic, :count)
  end
    
  it "should import an array of model objects" do
    topics = [Topic.new(:title=>"Ruby", :author_name=>"Matz"), Topic.new(:title=>"Lisp", :author_name=>"McCarthy")]
    lambda {
      Topic.import topics, :validate => true
    }.should change(Topic, :count).by(2)
    Topic.find_by_title_and_author_name("Ruby", "Matz").should_not be_nil
    Topic.find_by_title_and_author_name("Lisp", "McCarthy").should_not be_nil
  end

  it "should not import any data when validation fails on at least one model objects with validations turned on" do
    topics = [Topic.new(:title=>"Ruby", :author_name=>"Matz"), Topic.new(:title=>"Lisp")]
    lambda {
      result = Topic.import topics, :validate => true
      result.num_inserts.should == 0
    }.should change(Topic, :count).by(0)
  end

  it "should import data with an array of column names and an array of model objects" do
    topics = [
      Topic.new(:title=>"Ruby", :author_name=>"Matz", :content => "abc"), 
      Topic.new(:title=>"Lisp", :author_name=>"McCarthy", :content => "123")]
    lambda { 
      result = Topic.import [:title, :author_name], topics
      result.num_inserts.should == 2
    }.should change(Topic, :count).by(2)
    Topic.find_by_title_and_author_name("Ruby", "Matz").should_not be_nil
    Topic.find_by_title_and_author_name("Lisp", "McCarthy").should_not be_nil
  end

  it "should not import data with an array of column names and an invalid model object" do
    topics = [
      Topic.new(:title=>"Ruby", :author_name=>"", :content => "abc"), 
      Topic.new(:title=>"Lisp", :author_name=>"McCarthy", :content => "123")]
    lambda { 
      result = Topic.import [:title, :author_name], topics, :validate => true
      result.num_inserts.should == 0
    }.should change(Topic, :count).by(0)
  end
  
  it "should import data with an array of columns names and invalid model objects with validation turned off" do
    topics = [
      Topic.new(:title=>"Ruby", :author_name=>"", :content => "abc"), 
      Topic.new(:title=>"Lisp", :author_name=>"McCarthy", :content => "123")]
    lambda { 
      result = Topic.import [:title, :author_name, :content], topics, :validate => false
      result.num_inserts.should == 2
    }.should change(Topic, :count).by(2)
    Topic.find_by_title_and_author_name_and_content("Ruby", "", "abc").should_not be_nil
    Topic.find_by_title_and_author_name_and_content("Lisp", "McCarthy", "123").should_not be_nil
  end
end


describe ActiveRecord, "reporting on imported data" do
  before(:each) do
    ActiveRecord::Base.connection.begin_db_transaction
  end
  
  after(:each) do
    ActiveRecord::Base.connection.rollback_db_transaction
  end
    
  it "should report the number of instances that failed validation when given columns and values" do
    result = Topic.import(%w(title author_name), [%w(Ruby Matz), %w(Lisp)], :validate => true)
    result.failed_instances.should have(1).instances
  end
  
  it "should report the number of instances that failed validation when given models" do
    topics = [Topic.new(:title=>"Ruby"), Topic.new(:title=>"Lisp"), Topic.new(:title=>"Smalltalk", :author_name => "Kay")]
    result = Topic.import topics
    result.failed_instances.should have(2).instances
  end

  it "should report the number of instances that failed validation when given columns and models" do
    topics = [Topic.new(:title=>"Ruby"), Topic.new(:title=>"Lisp"), Topic.new(:title=>"Smalltalk", :author_name => "Kay")]
    result = Topic.import [:title], topics, :validate => true
    result.failed_instances.should have(2).instances
  end  
end


