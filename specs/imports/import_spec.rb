require File.expand_path(File.dirname(__FILE__)) + "/../spec_helper"
require "ar-extensions/import/active_record"

describe "ActiveRecord", "importing data" do
  it "should import data with array of columns and values" do
    lambda { 
      Topic.import(%w(title author_name), [%w(Ruby Matz), %w(Lisp McCarthy)])
    }.should change(Topic, :count).by(2)
    Topic.find_by_title_and_author_name!('Ruby', 'Matz').should_not be_nil
    Topic.find_by_title_and_author_name!('Lisp', 'McCarthy').should_not be_nil
  end
end