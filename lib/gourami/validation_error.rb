module Gourami
  class ValidationError < Gourami::Error

    def self.stringify_errors(errors)
      [].tap do |array|
        errors.each do |field, error|
          array.push("#{field}: #{error}")
        end
      end
    end

    # !@attribute [r] errors
    #   @return [Hash<Symbol, Array>]
    attr_reader :errors

    # Initialize the Gourami::ValidationError.
    #
    # @param errors [Hash<Symbol, Array>]
    def initialize(errors)
      @errors = errors
      super(message)
    end

    def message
      @message ||= "Validation failed with errors: #{stringify_errors.join("\n")}"
    end

    private

    def stringify_errors
      ValidationError.stringify_errors(errors)
    end

  end
end
