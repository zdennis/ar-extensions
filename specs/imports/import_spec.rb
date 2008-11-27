require File.expand_path(File.dirname(__FILE__)) + "/../spec_helper"
require "annex/import/active_record"

describe "ActiveRecord", "importing data" do
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
  
  it "should report the number of database inserts" do
    result = Topic.import(%w(title author_name), [%w(Ruby Matz), %w(Lisp McCarthy)], :validate => true)
    result.num_inserts.should == 2
  end
  
  it "should report the number of instances that failed to import with validation turned on" do
    result = Topic.import(%w(title author_name), [%w(Ruby Matz), %w(Lisp)], :validate => true)
    result.failed_instances.should have(1).instances
  end
  
  it "should import valid model objects" do
    topics = [Topic.new(:title=>"Ruby", :author_name=>"Matz"), Topic.new(:title=>"Lisp", :author_name=>"McCarthy")]
    lambda {
      Topic.import topics, :validate => true
    }.should change(Topic, :count).by(2)
  end

  it "should not import any data when validation fails on at least one model objects with validations turned on" do
    topics = [Topic.new(:title=>"Ruby", :author_name=>"Matz"), Topic.new(:title=>"Lisp")]
    lambda {
      result = Topic.import topics, :validate => true
      result.num_inserts.should == 0
    }.should change(Topic, :count).by(0)
  end

end

