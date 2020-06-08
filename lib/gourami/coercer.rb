module Gourami
  module Coercer

    # When it is being set, coerce the value of the attribute
    # according to the :type option.
    #
    # @param attribute_name [Symbol] name of the attribute
    # @param value [*] the value as it is passed into the setter
    # @param options [Hash] attribute options
    #
    # @return [*]
    def setter_filter(attribute_name, value, options)
      type = options[:type]
      coercer_method_name = :"coerce_#{type}"
      value = send(coercer_method_name, value, options) if type

      super(attribute_name, value, options)
    end

    # Coerce the value into a String.
    #
    # @param value [Object]
    # @option allow_nil [Boolean] (true)
    # @option nil_when_empty [Boolean] (true)
    # @option upcase [Boolean] (false)
    # @option strip [Boolean] (true)
    #
    # @return [String, nil]
    def coerce_string(value, options = {})
      if options.fetch(:allow_nil, true)
        return if value.nil?
        value = value.to_s
        return if value.empty? && options.fetch(:nil_when_empty, false)
      end

      value = value.to_s.dup.force_encoding(Encoding::UTF_8)
      value.strip! if options.fetch(:strip, true)
      value.upcase! if options.fetch(:upcase, false)

      value
    end

    # Corce the value into true or false.
    #
    # @param value [Object]
    # @option allow_nil [Boolean] (false)
    #
    # @return [Boolean, nil]
    def coerce_boolean(value, options = {})
      return if options[:allow_nil] && (value.nil? || value == "")
      return false if value.to_s.strip == "false"
      !!value && !coerce_string(value, :allow_nil => false).strip.empty?
    end

    # Coerce the value into an Array.
    #
    # @param value [Object]
    #   The value to be coerced.
    # @option element_type [Symbol, Hash] (nil)
    #   The type of the value to coerce each element of the array, if nil
    #   no coercion is performed.
    #   If a Hash is given, it is passed as options to the coercer.
    #
    # TODO docs for the rest of the options
    #
    # @return [Array]
    #   The coerced Array.
    def coerce_array(value, options = {})
      return if options[:allow_nil] && value.nil?

      element_type = options[:element_type]
      value = value.values if value.is_a?(Hash)

      if options[:split_by] && value.is_a?(String)
        value = value.split(options[:split_by]).map(&:strip)
      end

      return [] unless value.is_a?(Array)
      return value unless element_type

      if element_type.is_a?(Hash)
        element_type_options = element_type
        element_type = element_type[:type]
      else
        element_type_options = {}
      end

      coercer_method_name = :"coerce_#{element_type}"

      value.map do |array_element|
        send(coercer_method_name, array_element, element_type_options)
      end
    end

    # Coerce the value into a Float.
    #
    # @param value [Object]
    #
    # @return [Float, nil]
    def coerce_float(value, _options = {})
      Float(value) rescue nil
    end

    # Coerce the value into an international phone String.
    #
    # @param value [Object]
    #   The value to be coerced.
    #
    # @return [String, nil]
    def coerce_phone(value, options = {})
      value = coerce_string(value, options)
      value ? value.upcase.gsub(/[^+0-9A-Z]/, "") : nil
    end

    # Coerce the value into a Hash.
    #
    # @param value [Object]
    #   The value to be coerced.
    # @option options :key_type [Symbol, Callable] (nil)
    #   The type of the hash keys to coerce, no coersion if value is nil.
    # @option options :value_type [Symbol, Callable] (nil)
    #   The type of the hash values to coerce, no coersion if value is nil.
    # @option options :indifferent_access [Boolean] (false)
    #   When true, the resulting Hash will be an ActiveSupport::HashWithIndifferentAccess
    #
    # @return [Hash, ActiveSupport::HashWithIndifferentAccess]
    #   The coerced Hash.
    def coerce_hash(value, options = {})
      # return if options[:allow_nil] && value.nil?

      hash_key_type = options[:key_type]
      hash_value_type = options[:value_type]

      return {} unless value.is_a?(Hash) || (defined?(Sequel::Postgres::JSONHash) && value.is_a?(Sequel::Postgres::JSONHash))

      value.each_with_object({}) do |(key, value), coerced_hash|
        key_type = hash_key_type.respond_to?(:call) ? hash_key_type.call(key, value) : hash_key_type
        key = send("coerce_#{key_type}", key) if key_type

        value_type = hash_value_type.respond_to?(:call) ? hash_value_type.call(key, value) : hash_value_type
        value = send("coerce_#{value_type}", value) if value_type
        coerced_hash[key] = value
      end
    end

    # Coerce the value into an Integer.
    #
    # @param value [Object]
    #   The value to be coerced.
    #
    # @return [Integer, nil]
    #   An Integer if the value can be coerced or nil otherwise.
    def coerce_integer(value, _options = {})
      value = value.to_s
      return unless value =~ /\A0|[1-9]\d*\z/

      value.to_i
    end

    # Coerce the value into a Date.
    #
    # @param value [Object]
    #   The value to be coerced.
    #
    # @return [Date, nil]
    #   A Date if the value can be coerced or nil otherwise.
    def coerce_date(value, options = {})
      value = coerce_string(value, options)
      return if value.nil?
      begin
        Date.strptime(value, "%Y-%m-%d")
      rescue ArgumentError
        nil
      end
    end

    # Coerce the value into a Time.
    #
    # @param value [Object]
    #   The value to be coerced.
    #
    # @return [Time, nil]
    #   A Time if the value can be coerced or nil otherwise.
    def coerce_time(value, options = {})
      value = coerce_string(value, options)
      return if !value || value.empty?

      begin
        Time.parse(value).utc
      rescue ArgumentError
        nil
      end
    end

    # Coerce the value into a File. For the value to be successfully accepted as,
    # it should be a hash containing the :filename (String) and :tempfile
    # (File).
    #
    # @param value [Object]
    #
    # @return [Hash, nil]
    #   The hash will contain the file String :filename and the File :tempfile,
    #   or nil otherwise.
    def coerce_file(value, _options = {})
      return unless value.is_a?(Hash) && !value[:filename].to_s.empty?

      tempfile = value[:tempfile]
      return unless tempfile.is_a?(File) || tempfile.is_a?(Tempfile)

      value
    end

  end
end
