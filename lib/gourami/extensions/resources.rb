module Gourami
  module Extensions
    module Resources

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
        resource_errors[resource_namespace, resource_uid.to_s].values.map(&:flatten).any?
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

    end
  end
end
