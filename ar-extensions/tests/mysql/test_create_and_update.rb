require File.expand_path( File.join( File.dirname( __FILE__ ), '../test_helper') )

class CreateAndUpdateTest < TestCaseSuperClass
  if ActiveRecord::Base.connection.class.name =~ /sqlite/i
    self.use_transactional_fixtures = false
  end

  def setup
    super
    Animal.delete_all
  end

  #Input Validation Tests
  def test_replace_should_replace_existing_record_with_new_data
    create_animal
    assert_nil(@animal.size)

    new_animal = Animal.new(:name => 'giraffe', :size => 'big')
    assert_raise(ActiveRecord::StatementInvalid,
      "Should not be able to save duplicate.") { new_animal.save }

    new_animal.replace

    validate_animal(:size => 'big', :name => 'giraffe')
    assert(@animal.updated_at < @new_animal.updated_at)
    assert(@animal.created_at < @new_animal.created_at)
    assert(@new_animal.id > @animal.id)

    assert_nil(Animal.find_by_id(@original_animal_id))
  end

  #Input Validation Tests
  def test_create_ignore_without_duplicate_columns_should_throw_exception_for_missing_duplicate_columns
    assert_raise(ArgumentError) {
      test_create({:method => 'create'}, :ignore => true, :reload => true)
    }
  end

  def test_save_with_invalid_option_should_throw_exception
    assert_raise(ArgumentError) {
      test_save({:method => 'create'}, :ignore => true, :reload => true, :unknown_argument => true)
    }
  end

  #Create tests
  def test_create_ignore_should_ignore_existing_data
    test_create({:method => 'create'}, :ignore => true)
    validate_animal(:name => 'giraffe',
                    :updated_at => @animal.updated_at,
                    :created_at => @animal.created_at)
  end

  def test_create_ignore_with_reload_should_ignore_existing_data_then_reload
    create_animal

    @new_animal = Animal.create!({:name => 'giraffe', :size => 'little'}, :ignore => true)
    assert(@new_animal.stale_record?)
    assert_equal('little', @new_animal.size)

    @new_animal.reload_duplicate :duplicate_columns => [:name]
    assert(!@new_animal.stale_record?)
    assert_nil(@new_animal.size)
  end

  def test_create_bang_ignore_should_ignore_existing_data
    test_create({:method => 'create!'}, :ignore => true)
    validate_animal(:name => 'giraffe',
                    :updated_at => @animal.updated_at,
                    :created_at => @animal.created_at)
  end

  def test_create_duplicate_should_update_duplicate_data
    test_create({:method =>'create', :size => 'big'}, :on_duplicate_key_update => [:updated_at, :size])
    validate_animal(:name => 'giraffe',
                    :size => 'big',
                    :created_at => @animal.created_at)
    assert(@animal.updated_at < @new_animal.updated_at)
  end

  def test_create_bang_duplicate_should_update_duplicate_data
    test_create({:method =>'create!', :size => 'big'}, :on_duplicate_key_update => [:updated_at, :size])
    validate_animal(:name => 'giraffe',
                    :size => 'big',
                    :created_at => @animal.created_at)
    assert(@animal.updated_at < @new_animal.updated_at)
  end

  #Save insert tests
  def test_save_ignore_should_ignore_existing_data
    test_save({:method => 'save'}, :ignore => true)
    validate_animal(:name => 'giraffe',
                    :updated_at => @animal.updated_at,
                    :created_at => @animal.created_at)
  end

  def test_save_bang_ignore_should_ignore_existing_data_and_reload
    test_save({:method => 'save!'},
               :ignore => true, :reload => true, :duplicate_columns => [:name])
    validate_animal(:name => 'giraffe',
                    :updated_at => @animal.updated_at,
                    :created_at => @animal.created_at)
  end


  def test_save_duplicate_should_update_duplicate_data_and_reload
    test_save({:method =>'save', :size => 'big'},
                :on_duplicate_key_update => [:updated_at, :size],
                :reload => true, :duplicate_columns => [:name])

    validate_animal(:name => 'giraffe',
                    :size => 'big',
                    :created_at => @animal.created_at)

    assert(@animal.updated_at < @new_animal.updated_at)
  end

  def test_save_bang_duplicate_should_update_duplicate_data
    test_save({:method => 'save!', :size => 'big'},
               :on_duplicate_key_update => [:updated_at, :size])

    validate_animal(:name => 'giraffe',
                    :size => 'big',
                    :created_at => @animal.created_at)

    assert(@animal.updated_at < @new_animal.updated_at)
  end

  def test_save_existing_record_should_just_save_without_reload
    test_save_existing_record(:ignore => true)
    assert_equal(@bear.name, 'giraffe')
    assert_equal(@bear.size, 'huge')
  end

  def test_save_existing_record_should_just_save_with_reload
    test_save_existing_record(:ignore => true, :reload => true, :duplicate_columns => [:name])
    assert_equal(@bear.name, 'giraffe')
    assert_nil(@bear.size)
  end

  def test_save_existing_record_should_update_duplicate
    test_save_existing_record(:on_duplicate_key_update => [:updated_at, :size], :reload => true, :duplicate_columns => [:name])
    assert_equal(@bear.name, 'giraffe')
    assert_equal(@bear.size, 'huge')

    #ensure record was modified in database
    @bear = Animal.find_by_name('giraffe')
    assert_equal(@bear.name, 'giraffe')
    assert_equal(@bear.size, 'huge')
  end

  #RELOAD tests


    def test_create_ignore_with_reload_should_ignore_existing_data_then_reload
    create_animal

    @new_animal = Animal.create!({:name => 'giraffe', :size => 'little'}, :ignore => true)
    assert(@new_animal.stale_record?)
    assert_equal('little', @new_animal.size)

    @new_animal.reload_duplicate :duplicate_columns => [:name]
    assert(!@new_animal.stale_record?)
    assert_nil(@new_animal.size)
  end

  def test_save_should_update_existing_data_then_reload_later
    create_animal

    @new_animal = Animal.new :name => 'giraffe', :size => 'little'
    @new_animal.save!(:on_duplicate_key_update => [:updated_at])


    assert(@new_animal.stale_record?)
    assert_equal(0, @new_animal.id)
    assert_equal('little', @new_animal.size)
    assert(@animal.updated_at < @new_animal.updated_at)
    new_updated = @new_animal.updated_at

    @new_animal.reload_duplicate :duplicate_columns => [:name]

    assert(!@new_animal.stale_record?)
    assert_nil(@new_animal.size)
    assert_equal(new_updated.to_s, @new_animal.updated_at.to_s)
    assert_equal(@animal.id, @new_animal.id)
  end

  def test_update_should_delete_duplicate_record_on_reload
    create_animal

    @new_animal = Animal.create! :name => 'bear', :size => 'little'
    @new_animal.name = 'giraffe'
    assert(@new_animal.id > @animal.id)

    @new_animal.reload_duplicate :force => true, :duplicate_columns => [:name]
    assert(!@new_animal.stale_record?)
    assert_nil(@new_animal.size)
    assert_equal(@animal.updated_at.to_s, @new_animal.updated_at.to_s)
    assert_equal(@animal.id, @new_animal.id)
    assert_nil(Animal.find_by_name('bear'))

  end

  protected

  def test_create(options, ex_options)
    method = options.delete(:method)
    create_animal
    assert_raises(ActiveRecord::StatementInvalid,
      "Should not be able to create duplicate.") { Animal.send(method, {:name => 'giraffe'}) }
    @new_animal = Animal.send(method, {:name => 'giraffe'}.merge(options), ex_options)
    assert(@new_animal)
    validate_state_state(ex_options)
  end

  def test_save(options, ex_options)
    method = options.delete(:method)
    create_animal
    @new_animal = Animal.new({:name => 'giraffe'}.merge(options))
    assert_raise(ActiveRecord::StatementInvalid,
      "Should not be able to save duplicate.") { @new_animal.send(method) }
    assert(@new_animal.send(method, ex_options))
    validate_state_state(ex_options)
  end

  def validate_state_state(ex_options)
    if ex_options[:reload]
      assert_equal(@new_animal.created_at.to_s, @animal.created_at.to_s)
      assert(!@new_animal.stale_record?)
      assert_equal(@original_animal_id, @new_animal.id)
    else
      assert_equal(0, @new_animal.id)
      assert(@new_animal.created_at > @animal.created_at)
      assert(@new_animal.stale_record?)
      assert(Animal.find_by_name('giraffe'))
    end
  end

  def test_save_existing_record(save_options)
    @giraffe = create_animal

    @bear = create_animal(:name => 'bear')
    @bear.name = 'giraffe'
    @bear.size = 'huge'

    @original_bear_id = @bear.id
    @original_giraffe_id = @giraffe.id

    assert_raises(ActiveRecord::StatementInvalid,
      "Should not be able to create duplicate."){ @bear.save }

    @bear.save(save_options)
    assert(Animal.find_by_name('giraffe'))

    if save_options[:reload] || (save_options[:on_duplicate_key_update] && save_options[:duplicate_columns])
      assert_equal(@original_giraffe_id, @bear.id)
      assert(!@bear.stale_record?)
      assert_nil(Animal.find_by_name('bear'))
    else
      assert_equal(@original_bear_id, @bear.id)
      assert(@bear.stale_record?)
      assert(Animal.find_by_name('bear'))
    end
  end

  def create_animal(options={})
    Animal.create!(options.reverse_merge(:name => 'giraffe'))

    #back set the date so we can compare the new timestamp
    reset_time = Time.now - 1.day
    Animal.update_all(['updated_at = ?, created_at = ?', reset_time, reset_time])

    @animal = Animal.find_by_name options[:name] || 'giraffe'
    @original_animal_id = @animal.id
    @animal
  end

  def validate_animal(fields)
    @new_animal = Animal.find_by_name fields[:name]
    assert(@new_animal)

    assert(@new_animal.updated_at)
    assert(@new_animal.created_at)

    fields.each do|field, exp_val|
      assert_equal(exp_val.to_s, @new_animal.send(field).to_s,
        "Expecting #{exp_val} for #{field} but got #{@new_animal.send(field)}")
    end
  end

end
