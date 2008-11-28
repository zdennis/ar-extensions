require File.expand_path(File.dirname(__FILE__)) + "/../spec_helper"
require "annex/import/active_record"

describe ActiveRecord, "importing data" do
  before(:each) do
    ActiveRecord::Base.connection.begin_db_transaction
  end
  
  after(:each) do
    ActiveRecord::Base.connection.rollback_db_transaction
  end

  it "should import data with columns and values" do
    lambda { 
      result = Topic.import(%w(title author_name), [["Ruby", nil], ["Lisp", nil]])
      result.num_inserts.should == 0
    }.should_not change(Topic, :count)
  end
  
  it "should import data with columns and values with validations turned on" do
    lambda { 
      Topic.import(%w(title author_name), [%w(Ruby Matz), %w(Lisp McCarthy)], :validate => true)
    }.should change(Topic, :count).by(2)
    Topic.find_by_title_and_author_name('Ruby', 'Matz').should_not be_nil
    Topic.find_by_title_and_author_name('Lisp', 'McCarthy').should_not be_nil
  end

  it "should not import invalid data given columns and values with validations turned on" do
    lambda { 
      result = Topic.import(%w(title author_name), [%w(Ruby Matz), ["Lisp", nil]], :validate => true)
      result.num_inserts.should == 1
    }.should change(Topic, :count).by(1)
    Topic.find_by_title_and_author_name("Ruby", "Matz").should_not be_nil
  end
  
  it "should import invalid data given columns and values with validations turned off" do
    lambda { 
      result = Topic.import(%w(title author_name), [%w(Ruby Matz), ["Lisp", nil]], :validate => false)
      result.num_inserts.should == 2
    }.should change(Topic, :count).by(2)
    Topic.find_by_title_and_author_name("Ruby", "Matz").should_not be_nil
    Topic.find_by_title_and_author_name("Lisp", nil).should_not be_nil
  end
  
  it "should import valid data given models" do
    topics = [Topic.new(:title=>"Ruby", :author_name=>"Matz"), Topic.new(:title=>"Lisp", :author_name=>"McCarthy")]
    lambda {
      Topic.import topics
    }.should change(Topic, :count).by(2)
    Topic.find_by_title_and_author_name("Ruby", "Matz").should_not be_nil
    Topic.find_by_title_and_author_name("Lisp", "McCarthy").should_not be_nil
  end

  it "should import valid models with validations turned on" do
    topics = [Topic.new(:title=>"Ruby", :author_name=>"Matz"), Topic.new(:title=>"Lisp", :author_name=>"McCarthy")]
    lambda {
      Topic.import topics, :validate => true
    }.should change(Topic, :count).by(2)
    Topic.find_by_title_and_author_name("Ruby", "Matz").should_not be_nil
    Topic.find_by_title_and_author_name("Lisp", "McCarthy").should_not be_nil
  end

  it "should not import invalid models with validations turned on" do
    lambda { 
      result = Topic.import [Topic.new, Topic.new, Topic.new(:title => "Ruby", :author_name => "Matz")], :validate => true
      result.num_inserts.should == 1
    }.should change(Topic, :count).by(1)
    Topic.find_by_title_and_author_name("Ruby", "Matz").should_not be_nil
  end

  it "should import invalid models with validations turned off" do
    lambda { 
      topics = [Topic.new(:title => "Lisp"), Topic.new(:title => "Smalltalk"), Topic.new(:title => "Ruby", :author_name => "Matz")]
      result = Topic.import topics, :validate => false
      result.num_inserts.should == 3
    }.should change(Topic, :count).by(3)
    Topic.find_by_title_and_author_name("Smalltalk").should_not be_nil
    Topic.find_by_title_and_author_name("Lisp").should_not be_nil
    Topic.find_by_title_and_author_name("Ruby", "Matz").should_not be_nil
  end

  it "should import data given columns and models" do
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

  it "should import data given columns and models with validations turned on" do
    topics = [
      Topic.new(:title=>"Ruby", :author_name=>"Matz", :content => "abc"), 
      Topic.new(:title=>"Lisp", :author_name=>"McCarthy", :content => "123")]
    lambda { 
      result = Topic.import [:title, :author_name], topics, :validations => true
      result.num_inserts.should == 2
    }.should change(Topic, :count).by(2)
    Topic.find_by_title_and_author_name("Ruby", "Matz").should_not be_nil
    Topic.find_by_title_and_author_name("Lisp", "McCarthy").should_not be_nil
  end

  it "should not import invalid data given columns and models" do
    topics = [
      Topic.new(:title=>"Ruby", :author_name=>"", :content => "abc"), 
      Topic.new(:title=>"Lisp", :author_name=>"", :content => "123"),
      Topic.new(:title=>"Smalltalk", :author_name=>"Kay", :content => "xyz")]
    lambda { 
      result = Topic.import [:title, :author_name], topics
      result.num_inserts.should == 1
    }.should change(Topic, :count).by(1)
    Topic.find_by_title_and_author_name_and_content("Smalltalk", "Kay", nil).should_not be_nil
  end
  
  it "should not import invalid data given columns and models with validation turned on" do
    topics = [
      Topic.new(:title=>"Ruby", :author_name=>"", :content => "abc"), 
      Topic.new(:title=>"Lisp", :author_name=>"", :content => "123"),
      Topic.new(:title=>"Smalltalk", :author_name=>"Kay", :content => "xyz")]
    lambda { 
      result = Topic.import [:title, :author_name], topics, :validate => true
      result.num_inserts.should == 1
    }.should change(Topic, :count).by(1)
    Topic.find_by_title_and_author_name_and_content("Smalltalk", "Kay", nil).should_not be_nil
  end
  
  it "should import invalid data given columns and invalid models with validation turned off" do
    topics = [
      Topic.new(:title=>"Ruby", :author_name=>"", :content => "abc"), 
      Topic.new(:title=>"Lisp", :author_name=>"", :content => "123"),
      Topic.new(:title=>"Smalltalk", :author_name=>"Kay", :content => "xyz")]
    lambda { 
      result = Topic.import [:title, :author_name, :content], topics, :validate => false
      result.num_inserts.should == 3
    }.should change(Topic, :count).by(3)
    Topic.find_by_title_and_author_name_and_content("Ruby", "", "abc").should_not be_nil
    Topic.find_by_title_and_author_name_and_content("Lisp", "", "123").should_not be_nil
    Topic.find_by_title_and_author_name_and_content("Smalltalk", "Kay", "xyz").should_not be_nil
  end
end

describe ActiveRecord, "importing data with time stamp columns" do
  before(:each) do
    ActiveRecord::Base.connection.begin_db_transaction
  end
  
  after(:each) do
    ActiveRecord::Base.connection.rollback_db_transaction
  end

  %w(created_at created_on updated_at updated_on).each do |field|
    it "should set the #{field} column when importing new records" do
      Book.import [:title, :author_name, :publisher], [%w(Ruby Matz OReilly), %w(Rails DHH PragProg)]
      Book.find_by_title("Ruby").attributes[field].to_i.should be_close(Time.now.to_i, 10)
    end

    context "when setting the time zone to utc" do
      before(:each) do
        @original_timezone = ActiveRecord::Base.default_timezone
        ActiveRecord::Base.default_timezone = :utc
      end
      after(:each) do
        ActiveRecord::Base.default_timezone = @original_timezone
      end
      
      it "should set the #{field} column to ActiveRecord's time zone when importing new records" do
        Book.import [:title, :author_name, :publisher], [%w(Ruby Matz OReilly), %w(Rails DHH PragProg)]
        Book.find_by_title("Ruby").attributes[field].to_i.should be_close(Time.now.to_i, 10)
      end
    end
  end
end


describe ActiveRecord, "importing data that already exists" do
  before(:each) do
    ActiveRecord::Base.connection.begin_db_transaction
  end
  
  after(:each) do
    ActiveRecord::Base.connection.rollback_db_transaction
  end

  it "should not import a model whose primary key already exists in the database" do
    book = Book.create! :title=>"Ruby", :author_name=>"Matz", :publisher=>"PragProg"
    lambda {
      book.title = "Perl"
      begin ; Book.import [book] ; rescue ; end
    }.should_not change(Book, :count)
    Book.last.title.should == "Ruby"
  end
end


describe ActiveRecord, "importing data that uses reserved database words" do
  before(:each) do
    ActiveRecord::Base.connection.begin_db_transaction
  end
  
  after(:each) do
    ActiveRecord::Base.connection.rollback_db_transaction
  end

  it "should import data that uses reserved words given columns and values" do
    lambda {
      Group.import %w(order), %w(superfriends)
    }.should change(Group, :count).by(1)
    Group.find_by_order("superfriends").should_not be_nil
  end

  it "should import data that uses reserved words given models" do
    lambda {
      Group.import [Group.new(:order => "superfriends")]
    }.should change(Group, :count).by(1)
    Group.find_by_order("superfriends").should_not be_nil
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
    result = Topic.import(%w(title author_name), [%w(Ruby Matz), ["Lisp", nil]], :validate => true)
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


