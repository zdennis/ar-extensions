require File.expand_path(File.dirname(__FILE__)) + "/../spec_helper"
require "annex/import/active_record"

describe "generating INSERT INTO statements" do
  
  it "should generate an SQL statement" do
    generator = ContinuousThinking::SQL::Generator.for(:insert_into)
    generator.table = "people"
    generator.columns = %w(name age sex)
    generator.values = [%w('Zach' 26 'M'), %w('Bob' 24 'M')]
    generator.to_sql_statements.should == ["INSERT INTO people (name,age,sex) VALUES ('Zach',26,'M'),('Bob',24,'M')"]
  end

  it "should generate multiple SQL statements which each fit within the maximum byte size allowed" do
    generator = ContinuousThinking::SQL::Generator.for(:insert_into)
    generator.max_bytes_per_statement = 57
    generator.table = "people"
    generator.columns = %w(name age sex)
    generator.values = [%w('Zach' 26 'M'), %w('Bob' 24 'M')]
    generator.to_sql_statements.should == [
      "INSERT INTO people (name,age,sex) VALUES ('Zach',26,'M')",
      "INSERT INTO people (name,age,sex) VALUES ('Bob',24,'M')"
    ]
  end
end


