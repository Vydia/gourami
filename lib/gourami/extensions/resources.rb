module Gourami
  module Extensions
    module Resources

      # yield to the given block for each resource in the given namespace.
      #
      # @param resource_namespace [Symbol] The namespace of the resource (e.g. :users, :payments)
      #
      # @option offset [Integer] The offset of the resource (e.g. 0, 1, 2) for example in an update form, there may be existing items that already exist, however only the new items are sent to the form.
      #
      # @yield The block to execute, each time with a resource active.
      #
      # @example
      #   def validate
      #     with_each_resource(:social_broadcasts) do
      #       validate_presence(:title) # validates `attributes[:social_broadcasts][<EACH>][:title]`
      #     end
      #   end
      def with_each_resource(resource_namespace, offset: nil, &_block)
        resources = send(resource_namespace)
        if resources.is_a?(Hash)
          return resources.each_with_index do |(resource_uid, resource), index|
            with_resource(resource_namespace, resource_uid, offset: offset) do
              yield(resource, resource_uid, index)
            end
          end
        end

        send(resource_namespace).each_with_index do |resource, index|
          with_resource(resource_namespace, index, offset: offset) do
            yield(resource, offset ? index + offset : index, index)
          end
        end
      end

      # For the duration of the given block, all validations will be done on the given resource.
      #
      # @param resource_namespace [Symbol] The namespace of the resource (e.g. :users, :payments)
      # @param resource_uid [String|Number] The uid of the resource (e.g. 0, 1, "123")
      #
      # @option offset [Integer] The offset of the resource (e.g. 0, 1, 2) for example in an update form, there may be existing items that already exist, however only the new items are sent to the form.
      #
      # @yield The block to execute with the resource active.
      #
      # @example
      #   def validate
      #     validate_presence(:title) # validates `attributes[:title]` of the form
      #
      #     with_resource(:social_broadcasts, "facebook_page-41") do
      #       # Within this block all validations will be done on the resource.
      #       validate_presence(:title)           # validates `attributes[:social_broadcasts]["facebook_page-41"][:title]`
      #       validate_presence(:trim_start_time) # validates `attributes[:social_broadcasts]["facebook_page-41"][:trim_start_time]`
      #       validate_presence(:trim_end_time)   # validates `attributes[:social_broadcasts]["facebook_page-41"][:trim_end_time]`
      #     end
      #   end
      def with_resource(resource_namespace, resource_uid, offset: nil, &_block)
        @resource_namespace = resource_namespace
        @resource_uid = resource_uid
        @offset = offset
        yield
      ensure
        @resource_namespace = nil
        @resource_uid = nil
        @offset = nil
      end

      # If a resource namespace is active (within with_resource block), find the resource using the namespace and uid.
      # Otherwise, return the form object.
      def current_resource
        if @resource_namespace
          send(@resource_namespace)[@resource_uid]
        else
          super
        end
      end

      # If a resource namespace is active (within with_resource block), append the error to the resource.
      # Otherwise, append the error to the form object.
      def append_error(attribute_name, message)
        if @resource_namespace
          append_resource_error(@resource_namespace, @offset ? @resource_uid + @offset : @resource_uid, attribute_name, message)
        else
          super
        end
      end

      # Return a deeply nested Hash which allows you to identify errors by resource.
      #
      # @return [Hash<Symbol>]
      #
      # @example
      #   resource_errors
      #   # => {
      #   #   :social_broadcasts => {
      #   #     :"facebook_page-41" => {
      #   #       :trim_start_time => [:is_invalid, :is_too_short],
      #   #       :trim_end_time => [:is_invalid]
      #   #     },
      #   #     :"youtube_account-42" => {
      #   #       :title => [:is_too_short]
      #   #     }
      #   #   },
      #   #   :another_resource => {
      #   #     :"other_resource_id-12" => {
      #   #       :something => [:is_too_long]
      #   #     }
      #   #   }
      #   # }
      #
      #   resource_errors[:social_broadcasts]
      #   # => {
      #   #   :"facebook_page-41" => {
      #   #     :trim_start_time => [:is_invalid, :is_too_short],
      #   #     :trim_end_time => [:is_invalid]
      #   #   },
      #   #   :"youtube_account-42" => {
      #   #     :title => [:is_too_short]
      #   #   }
      #   # }
      #
      #   resource_errors[:social_broadcasts][:"facebook_page-41"]
      #   # => {
      #   #   :trim_start_time => [:is_invalid, :is_too_short],
      #   #   :trim_end_time => [:is_invalid]
      #   # }
      #
      #   resource_errors[:social_broadcasts][:"facebook_page-41"][:trim_start_time]
      #   # => [:is_invalid, :is_too_short]
      def resource_errors
        @resource_errors ||= Hash.new do |resource_errors, resource_name|
          resource_errors[resource_name] = Hash.new do |resource_uids, resource_uid|
            resource_uids[resource_uid] = Hash.new do |attributes, attribute_name|
              attributes[attribute_name] = []
            end
          end
        end
      end

      # TODO: YARD
      def resource_has_errors?(resource_namespace, resource_uid)
        resource_errors[resource_namespace][resource_uid.to_s].values.map(&:flatten).any?
      end

      # TODO: YARD
      def resource_attribute_has_errors?(resource_namespace, resource_uid, attribute_name)
        resource_errors[resource_namespace][resource_uid.to_s][attribute_name].any?
      end

      # Append an error to the given attribute for a resource.
      # TODO: consider coercing attribute_name `.to_s` too.
      #
      # @param resource_namespace [Symbol]
      # @param resource_uid [String]
      # @param attribute_name [Symbol]
      # @param error [Symbol, String]
      #   The error identifier.
      def append_resource_error(resource_namespace, resource_uid, attribute_name, error)
        resource_errors[resource_namespace][resource_uid.to_s][attribute_name] << error
      end

      # Determine if current form instance is valid by running the validations
      #   specified on #validate.
      #
      # @return [Boolean]
      def any_errors?
        super || any_resource_errors?
      end

      # Return true if any resources by any uids have any errors.
      #
      # @return [Boolean]
      def any_resource_errors?
        resource_errors.values.flat_map(&:values).map(&:values).flatten.any?
      end

      # Replace the existing resource errors with the provided errors Hash.
      #
      # @param new_resource_errors [Hash<Symbol, Hash<Symbol, Hash<Symbol, Array>>>]
      #
      # @return [Hash<Symbol, Hash<Symbol, Hash<Symbol, Array>>>]
      def clear_and_set_resource_errors(new_resource_errors)
        new_resource_errors = new_resource_errors.dup
        resource_errors.clear
        resource_errors.merge!(new_resource_errors)

        resource_errors
      end

      def handle_validation_error(error)
        super(error)
        clear_and_set_resource_errors(error.resource_errors) unless error.resource_errors.nil?
      end

      def raise_validate_errors
        raise ValidationError.new(errors, resource_errors)
      end

    end
  end
end
