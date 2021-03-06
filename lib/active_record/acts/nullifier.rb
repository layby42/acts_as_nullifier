module ActiveRecord
  module Acts   #:nodoc:
    module Nullifier   #:nodoc:
      def self.included(base)
        base.extend(ClassMethods)
      end
    end
    
    module ClassMethods
      ##
      # Ask model to store NULLs instead of empty strings in the database.
      # Configuration options are:
      #   * +:only+: nullify only these attributes (non-string and not NULLable attributes will be ignored)
      #   * +:except+: nullify all :string attributes that allow NULLs, except these
      #
      # Example:
      #
      #   class Group < ActiveRecord::Base  #:nodoc:
      #     acts_as_nullifier :except => :name
      #   end
      #
      #   class User < ActiveRecord::Base  #:nodoc:
      #     acts_as_nullifier :only => [:first_name, :last_name]
      #   end
      #
      def acts_as_nullifier(options = {})
        @nullable_attributes = nil
        
        self.instance_eval do
          define_method :nullable_attributes do
            if @nullable_attributes.nil?
              only = [options[:only] || self.class.columns.map { |column| column.name.to_sym }].flatten
              except = [options[:except] || []].flatten
              @nullable_attributes = only - except
            end
            @nullable_attributes
          end
        end
        
        include ActiveRecord::Acts::InstanceMethods
      end
    end
    
    module InstanceMethods
      protected
      
      ##
      # Write NULLs instead of empty strings for all :string columns that allow NULLs
      # Value of 'all' can be adjusted with +:only+ and +:except+ options to +acts_as_nullifier+
      #
      def write_attribute(name, value)
        if self.nullable_attributes.include? name.to_sym
          column = column_for_attribute(name)
          if column && (column.type == :string || column.type == :text) && column.null == true
            value = nil if value == ''
          end
        end
        super(name, value)
      end
    end
  end
end