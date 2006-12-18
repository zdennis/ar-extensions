ActiveRecord::Schema.define do
#  tables.each { |table| drop_table( table ) }
 
  create_table :test_myisam, :options=>'ENGINE=MyISAM', :force=>true do |t|
    t.column :my_name, :string, :null=>false
    t.column :description, :string
  end
  
  create_table :test_innodb, :options=>'ENGINE=InnoDb', :force=>true do |t|
    t.column :my_name, :string, :null=>false
    t.column :description, :string
  end

  create_table :test_memory, :options=>'ENGINE=Memory', :force=>true do |t|
    t.column :my_name, :string, :null=>false
    t.column :description, :string
  end
  
  create_table :topics, :force=>true do |t|
    t.column :title, :string, :null=>false
    t.column :author_name, :string
    t.column :author_email_address, :string
    t.column :written_on, :datetime
    t.column :bonus_time, :time
    t.column :last_read, :datetime
    t.column :content, :text
    t.column :approved, :boolean, :default=>'1'
    t.column :replies_count, :integer
    t.column :parent_id, :integer
    t.column :type, :string    
  end
  
  create_table :projects, :force=>true do |t|
    t.column :name, :string
    t.column :type, :string    
  end
  
  create_table :developers, :force=>true do |t|
    t.column :name, :string
    t.column :salary, :integer, :default=>'70000'
    t.column :created_at, :datetime
    t.column :updated_at, :datetime
  end
  
  create_table :books, :options=>'ENGINE=MyISAM', :force=>true do |t|
    t.column :title, :string, :null=>false
    t.column :publisher, :string, :null=>false
    t.column :author_name, :string, :null=>false
  end
  execute "ALTER TABLE books ADD FULLTEXT( `title`, `publisher`, `author_name` )"
  
end
