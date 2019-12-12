module Gourami
  class ValidationError < Gourami::Error

    def self.stringify_errors(errors)
      [].tap do |array|
        errors.each do |field, error|
          array.push("#{field}: #{error}")
        end
      end
    end

    def self.stringify_resource_errors(resource_errors)
      [].tap do |array|
        resource_errors.each do |resource_namespace, resource_namespace_errors|
          resource_namespace_errors.each do |resource_uid, resource_uid_errors|
            resource_uid_errors.each do |attribute_name, error|
               array.push("#{resource_namespace}:#{resource_uid}:#{attribute_name}: #{error}")
            end
          end
        end
      end
    end

    # !@attribute [r] errors
    #   @return [Hash<Symbol, Array>]
    attr_reader :errors

    # !@attribute [r] resource_errors
    #   @return [Hash<Symbol, Hash<Symbol, Hash<Symbol, Array>>>]
    attr_reader :resource_errors

    # Initialize the Gourami::ValidationError.
    #
    # @param errors [Hash<Symbol, Array>]
    # @param resource_errors [Hash<Symbol, Hash<Symbol, Hash<Symbol, Array>>>]
    def initialize(errors, resource_errors = nil)
      @resource_errors = resource_errors
      @errors = errors

      super(message)
    end

    def message
      @message ||= stringify_all_errors
    end

    private

    def stringify_errors
      ValidationError.stringify_errors(errors)
    end

    def stringify_resource_errors
      ValidationError.stringify_resource_errors(resource_errors)
    end

    def stringify_all_errors
      messages = []
      messages << "Validation failed with errors: #{stringify_errors.join("\n")}" unless errors.nil?
      p "test message", errors
      messages << "Validation failed with resource errors: #{stringify_resource_errors.join("\n")}" unless resource_errors.nil?
      messages.join("\n")
    end

  end
end
