module ActiveRecord::Extensions::Delete#:nodoc:
  mattr_accessor :delete_batch_size
  self.delete_batch_size = 15000

  module DeleteSupport #:nodoc:
    def supports_delete? #:nodoc:
      true
    end
  end
end

class ActiveRecord::Base
  supports_extension :delete
  
  class << self

      # Delete all specified records with options
      #
      # == Parameters
      # * +conditions+ - the conditions normally specified to +delete_all+
      # * +options+ - hash map of additional parameters
      #
      # == Options
      # * <tt>:limit</tt> - the maximum number of records to delete.
      # * <tt>:batch</tt> - delete in batches specified to avoid database contention
      # Multiple sql deletions are executed in order to avoid database contention
      # This has no affect if used inside a transaction
      #
      # Delete up to 65 red tags
      #  Tag.delete_all ['name like ?', '%red%'], :limit => 65
      #
      # Delete up to 65 red tags in batches of 20. This will execute up to
      # 4 delete statements: 3 batches of 20 and the final batch of 5.
      #  Tag.delete_all ['name like ?', '%red%'], :limit => 65, :batch => 20
      def delete_all_with_extension(conditions = nil, options={})

        #raise an error if delete is not supported and options are specified
        supports_delete! if options.any?

        #call the base method if no options specified
        return delete_all_without_extension(conditions) unless options.any?

        #batch delete
        return delete_all_batch(conditions, options[:batch], options[:limit]) if options[:batch]

        #regular delete with limit
        connection.delete(delete_all_extension_sql(conditions, options), "#{name} Delete All")
      end

      alias_method_chain :delete_all, :extension


      # Utility function to delete all but one of the duplicate records
      # matching the fields specified. This method will make the records
      # unique for the specified fields.
      #
      # == Options
      # * <tt>:fields</tt> - the fields to match on
      # * <tt>:conditions</tt> - additional conditions
      # * <tt>:winner_clause</tt> - the part of the query specifying what wins. Default winner is that with the greatest id.
      # * <tt>:query_field</tt> -> the field to use to determine the winner. Defaults to primary_key (id). The tables are aliased
      #  to c1 and c2 respectively
      # == Examples
      # Make all the phone numbers of contacts unique by deleting the duplicates with the highest ids
      #   Contacts.delete_duplicates(:fields=>['phone_number_id'])
      #
      # Delete all tags that are the same preserving the ones with the highest id
      #   Tag.delete_duplicates :fields => [:name], :winner_clause => "c1.id < c2.id"
      #
      # Remove duplicate invitations (those that from the same person and to the same recipient)
      # preseving the first ones inserted
      #  Invitation.delete_duplicates :fields=>[:event_id, :from_id, :recipient_id]
      def delete_duplicates(options={})
        supports_delete!

        options[:query_field]||= primary_key

        query = "DELETE FROM"
        query << " c1 USING #{quoted_table_name} c1, #{quoted_table_name} c2"
        query << " WHERE ("
        query << options[:fields].collect{|field| "c1.#{field} = c2.#{field}" }.join(" and ")
        query << " and (#{sanitize_sql(options[:conditions])})" unless options[:conditions].blank?
        query << " and "
        query << (options[:winner_clause]||"c1.#{options[:query_field]} > c2.#{options[:query_field]}")
        query << ")"

        self.connection.execute(self.send(:sanitize_sql, query))
      end

      protected


      # Delete all records specified in batches
      #
      # == Parameters
      # * +conditions+ - the conditions normally specified to +delete_all+
      # * +batch+ - the size of the batches to delete. defaults to 15000
      # * +limit+ - the maximum number of records to delete
      #
      def delete_all_batch(conditions=nil, batch=nil, limit=nil)#:nodoc:

        #update the batch size if batch is nil or true or 0
        if batch.nil? || !batch.is_a?(Fixnum) || batch.to_i == 0
          batch = ActiveRecord::Extensions::Delete.delete_batch_size
        end


        sql = delete_all_extension_sql(conditions, :limit => batch)
        page_num = total = 0

        loop {
          page_num += 1

          #if this is the last batch query and limit is set
          #only delete the remainer
          if limit && (total + batch > limit)
             sql = delete_all_extension_sql(conditions, :limit => (limit - total))
          end

          count = connection.delete(sql, "#{name} Delete All Batch #{page_num}")
          total += count

          # Return if
          #  * last query did not return the batch size (meaning nothing left to delete)
          #  * we have reached our limit
           if (count < batch) || (limit && (total >= limit))
             return total
           end
        }
      end

      #generate the delete SQL with limit
      def delete_all_extension_sql(conditions, options={})#:nodoc:
        sql = "DELETE FROM #{quoted_table_name} "
        add_conditions!(sql, conditions, scope(:find))
        connection.add_limit_offset!(sql, options)
        sql
      end

  end

end

