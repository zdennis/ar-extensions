ActiveRecord::Schema.define do
  
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

  create_table :addresses, :force=>true do |t|
    t.column :address, :string
    t.column :city, :string
    t.column :state, :string
    t.column :zip, :string
    t.column :developer_id, :integer
  end
  
  create_table :books, :force=>true do |t|
    t.column :title, :string, :null=>false
    t.column :publisher, :string, :null=>false
    t.column :author_name, :string, :null=>false
  end  

end
