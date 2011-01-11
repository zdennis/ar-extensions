ActiveRecord::ConnectionAdapters::Mysql2Adapter.class_eval do
  # Returns the maximum number of bytes that the server will allow
  # in a single packet
  def max_allowed_packet # :nodoc:
    result = execute( "SHOW VARIABLES like 'max_allowed_packet';" )
    result.first[1].to_i
  end

  def rollup_sql; " WITH ROLLUP "; end
end
