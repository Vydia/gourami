require_relative "./formatting_constants"

module Gourami
  module Validations

    include Gourami::FormattingConstants

    def validate
      # Override to add custom validations
    end

    # Validate and perform the form actions. If any errors come up during the
    #   validation or the #perform method, raise an exception with the errors.
    #
    # @raise [Gourami::ValidationError]
    def perform!
      if valid?
        returned = perform
      end

      if any_errors?
        raise ValidationError.new(errors)
      end

      returned
    end

    # Get the current form errors Hash.
    #
    # @return [Hash<Symbol, nil>, Array<Symbol, String>]
    #   The errors Hash, having the Symbol attribute names as keys and an
    #   array of errors (Symbols) as the value.
    def errors
      @errors ||= Hash.new { |hash, key| hash[key] = [] }
    end

    # Determine if current form instance is valid by running the validations
    #   specified on #validate.
    #
    # @return [Boolean]
    def valid?
      errors.clear
      validate
      !any_errors?
    end

    # Replace the existing errors with the provided errors Hash.
    #
    # @param new_errors [Hash<Symbol, nil>, Array<Symbol, String>]
    #
    # @return [Hash<Symbol, nil>, Array<Symbol, String>]
    def clear_and_set_errors(new_errors)
      new_errors = new_errors.dup
      errors.clear
      errors.merge!(new_errors)

      errors
    end

    # Return true if there given attribute has any errors.
    def attribute_has_errors?(attribute_name)
      errors[attribute_name.to_sym].any?
    end

    # Return true if there are any errors.
    def any_errors?
      errors.reject{ |k,v| v.empty? }.any?
    end

    # Append an error to the given attribute.
    #
    # @param attribute_name [Symbol, nil] nil for base
    # @param error [Symbol, String]
    #   The error identifier.
    def append_error(attribute_name, error)
      errors[attribute_name] << error
    end

    # Validate the presence of the attribute value. If the value is nil or
    #   false append the :cant_be_empty error to the attribute.
    #
    # @param attribute_name [Symbol]
    def validate_presence(attribute_name, message = nil)
      value = send(attribute_name)
      if !value || value.to_s.strip.empty?
        append_error(attribute_name, message || :cant_be_empty)
      end
    end

    # Validate the uniqueness of the attribute value. The uniqueness is
    #   determined by the block given. If the value is not unique, append the
    #   :is_duplicated error to the attribute.
    #
    # @param attribute_name [Symbol]
    # @param block [Proc]
    #   A block to determine if a given value is unique or not. It receives
    #   the value and returns true if the value is unique.
    def validate_uniqueness(attribute_name, message = nil, &block)
      value = send(attribute_name)
      unless block.call(value)
        append_error(attribute_name, message || :is_duplicated)
      end
    end

    # Validate the email format. If the value does not match the email format,
    #   append the :is_invalid error to the attribute.
    #
    # @param attribute_name [Symbol]
    def validate_email_format(attribute_name, message = nil)
      validate_format(attribute_name, EMAIL_FORMAT, message)
    end

    def validate_isrc_format(attribute_name, message = nil)
      validate_format(attribute_name, ISRC_FORMAT, message)
    end

    def validate_color_format(attribute_name, message = nil)
      validate_format(attribute_name, HEX_COLOR_FORMAT, message)
    end

    # Validate the format of the attribute value. If the value does not match
    #   the regexp given, append :is_invalid error to the attribute.
    #
    # @param attribute_name [Symbol]
    # @param format [Regexp]
    def validate_format(attribute_name, format, message = nil)
      value = send(attribute_name)
      if value && !(format =~ value)
        append_error(attribute_name, message || :is_invalid)
      end
    end

    # Validate the length of a String, Array or any other form attribute which
    #   responds to #size. If the value is too short, append the :too_short
    #   error to the attribute. If the value is too long append the :too_long
    #   error to the attribute.
    #
    # @param attribute_name [Symbol]
    # @option options [Integer, nil] :min (nil)
    # @option options [Integer, nil] :max (nil)
    def validate_length(attribute_name, options = {})
      # TODO: Support :unless_already_invalid => true in more validators.
      return if options.fetch(:unless_already_invalid, false) && attribute_has_errors?(attribute_name)

      min = options.fetch(:min, nil)
      max = options.fetch(:max, nil)
      value = send(attribute_name)

      return if options[:allow_blank] && value.blank?

      if value
        length = value.size
        did_append_error = false

        if min && length < min
          did_append_error = true
          append_error(attribute_name, options.fetch(:min_message, nil) || :is_too_short)
        end
        if max && length > max
          did_append_error = true
          append_error(attribute_name, options.fetch(:max_message, nil) || :is_too_long)
        end

        errors[attribute_name] if did_append_error
      end
    end

    # Validate the value of the given attribute is included in the list. If
    #   the value is not included in the list, append the :not_listed error to
    #   the attribute.
    #
    # @param attribute_name [Symbol]
    # @param list [Array]
    def validate_inclusion(attribute_name, list, message = nil)
      value = send(attribute_name)
      if value && !list.include?(value)
        append_error(attribute_name, message || :isnt_listed)
      end
    end

    # Validate the presence of each object in attribute name within list. If the object
    #   is not included in the list, append the :not_listed error to the attribute.
    def validate_inclusion_of_each(attribute_name, list, message = nil)
      value = send(attribute_name)
      value && value.each do |obj|
        unless list.include?(obj)
          append_error(attribute_name, message || "#{obj} isn't listed")
          break
        end
      end
    end

    # Validate the value of the given attribute is not empty.
    # Appends :cant_be_empty error.
    #
    # @param attribute_name [Symbol]
    def validate_any(attribute_name, message = nil)
      value = send(attribute_name)
      if value && value.empty?
        append_error(attribute_name, message || :cant_be_empty)
      end
    end

    # Validate the type of the file sent if included in the list. If it's not,
    #   append an :invalid_file error to the attribute.
    #
    # @param attribute_name [Symbol]
    # @param filetypes [Array<String>]
    def validate_filetype(attribute_name, filetypes, message = nil)
      value = send(attribute_name)
      if value && !filetypes.include?(value[:type].to_s.split("/").first)
        append_error(attribute_name, message || :is_invalid)
      end
    end

    # Validate the range in which the attribute can be. If the value is less
    #   than the min a :less_than_min error will be appended. If the value is
    #   greater than the max a :greater_than_max error will be appended.
    #
    # @param attribute_name [Symbol]
    # @option options [Integer] :min (nil)
    #   The minimum value the attribute can take, if nil, no validation is made.
    # @option options [Integer] :max (nil)
    #   The maximum value the attribute can take, if nil, no validation is made.
    def validate_range(attribute_name, options = {})
      value = send(attribute_name)

      return unless value

      min = options.fetch(:min, nil)
      max = options.fetch(:max, nil)
      append_error(attribute_name, options.fetch(:min_message, nil) || :less_than_min) if min && value < min
      append_error(attribute_name, options.fetch(:max_message, nil) || :greater_than_max) if max && value > max
    end

  end
end
