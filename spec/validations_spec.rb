require_relative "./spec_helper"

describe Gourami::Validations do
  let(:form_class) do
    Class.new.tap do |c|
      c.send(:include, Gourami::Attributes)
      c.send(:include, Gourami::Validations)
    end
  end

  describe "#validate" do
    it "adds items to the errors hash" do
      form = form_class.new

      form.define_singleton_method(:validate) do
        form.append_error(:whatever, :error_message)
      end

      form.validate
      assert_equal({ :whatever => [:error_message] }, form.errors)
    end
  end

  describe "#valid?" do
    it "returns true if the form has no errors" do
      form = form_class.new
      assert_equal(true, form.valid?)
    end

    it "returns false if the form has any errors" do
      form = form_class.new

      form.define_singleton_method(:validate) do
        form.append_error(:whatever, :error_message)
      end

      assert_equal(false, form.valid?)
    end

    it "clears pre-existing errors before calling #validate" do
      form = form_class.new
      form.append_error(:whatever, :error_message)

      form.define_singleton_method(:validate) do
        # Do nothing.
      end

      assert_equal(true, form.valid?)
    end
  end

  describe "#perform!" do
    it "raises a ValidationError if the form has any errors" do
      form = form_class.new

      form.define_singleton_method(:validate) do
        form.append_error(:whatever, :error_message)
      end

      error = assert_raises(Gourami::ValidationError) do
        form.perform!
      end

      assert_equal(
        %Q(Validation failed with errors: whatever: [:error_message]),
        error.message
      )
    end
  end

  describe "#attribute_has_errors?" do
    it "returns true when an attribute has at least one error" do
      form = form_class.new
      form.append_error(:whatever, :error_message)
      assert_equal(true, form.attribute_has_errors?(:whatever))
    end

    it "returns false when an attribute has no errors" do
      form = form_class.new
      assert_equal(false, form.attribute_has_errors?(:whatever))

      form.instance_variable_set(:@errors, :whatever => [])
      assert_equal(false, form.attribute_has_errors?(:whatever))
    end
  end

  describe "#any_errors?" do
    it "returns true when an any attributes have has at least one error" do
      form = form_class.new
      form.append_error(:whatever, :error_message)
      assert_equal(true, form.any_errors?)
    end

    it "returns false when no attributes have any errors" do
      form = form_class.new
      assert_equal(false, form.any_errors?)

      form.instance_variable_set(:@errors, :whatever => [])
      assert_equal(false, form.any_errors?)
    end
  end
end
