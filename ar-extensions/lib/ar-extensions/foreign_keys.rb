module ActiveRecord::Base::ForeignKeys

  # ActiveRecord::Base.foreign_keys.disable

  #TODO: Dont modify external state
  def self.disable
    if block_given?
      disable
      yield
      enable
    else
      connection.execute "set foreign_key_checks = 0"
    end
  end

  def self.enable
    if block_given?
      enable
      yield
      disable
    else
      connection.execute "set foreign_key_checks = 1"
    end
  end
end
