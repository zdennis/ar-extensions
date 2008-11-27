require File.expand_path(File.dirname(__FILE__)) + "/../spec_helper"
require "annex/import/active_record"

describe "ActiveRecord", "importing data" do
  it "should import data with array of columns and values" do
    lambda { 
      Topic.import(%w(title author_name), [%w(Ruby Matz), %w(Lisp McCarthy)])
    }.should change(Topic, :count).by(2)
    Topic.find_by_title_and_author_name!('Ruby', 'Matz').should_not be_nil
    Topic.find_by_title_and_author_name!('Lisp', 'McCarthy').should_not be_nil
  end
    
  it "should import valid data with validations turned on" do
    lambda { 
      Topic.import(%w(title author_name), [%w(Ruby Matz), %w(Lisp McCarthy)], :validate => true)
    }.should change(Topic, :count).by(2)
    Topic.find_by_title_and_author_name!('Ruby', 'Matz').should_not be_nil
    Topic.find_by_title_and_author_name!('Lisp', 'McCarthy').should_not be_nil    
  end
  
  it "should not import any data when validation fails on at least one record with validations turned on" do
    lambda { 
      Topic.import(%w(title author_name), [%w(Ruby Matz), %w(Lisp)], :validate => true)
    }.should_not change(Topic, :count)
  end
  
  it "should report the number of database inserts" do
    result = Topic.import(%w(title author_name), [%w(Ruby Matz), %w(Lisp McCarthy)])
    result.num_inserts.should == 2
  end
  
  it "should report the number of instances that failed to import with validation turned on" do
    result = Topic.import(%w(title author_name), [%w(Ruby Matz), %w(Lisp)], :validate => true)
    result.failed_instances.should have(1).instances
  end
  
  it "should report no database inserts when validation fails on at least one record with validation turned on" do
    result = Topic.import(%w(title author_name), [%w(Ruby Matz), %w(Lisp)], :validate => true)
    result.num_inserts.should == 0
  end
end

