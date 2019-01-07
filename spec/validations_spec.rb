require_relative "./spec_helper"

describe Gourami::Validations do
  let(:form_class) do
    Class.new.tap do |c|
      c.send(:include, Gourami::Attributes)
      c.send(:include, Gourami::Validations)
      c.attribute :whatever
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

  describe Gourami::Validations do
    def self.it_fails_validations(opts)
      attribute_name = opts.fetch(:attribute_name)
      method_name = opts.fetch(:method_name)
      opts.fetch(:cases).each do |attribute_value, args, expected_errors|
        describe "#{method_name} when value is #{attribute_value.inspect} called with args #{args.inspect}" do
          it "results in errors #{expected_errors.inspect} on the attribute and returns all the errors on the attribute" do
            form = form_class.new(attribute_name => attribute_value)
            preceding_error = :foo
            assert_equal(false, form.any_errors?)
            form.append_error(attribute_name, preceding_error)
            assert_equal({ attribute_name => [preceding_error] }, form.errors)
            assert_equal(true, form.any_errors?)
            returned = form.send(method_name, attribute_name, *args)
            assert_equal([preceding_error] + expected_errors, returned)
            assert_equal({ attribute_name => [preceding_error] + expected_errors }, form.errors)
          end
        end
      end
    end

    def self.it_passes_validations(opts)
      attribute_name = opts.fetch(:attribute_name)
      method_name = opts.fetch(:method_name)
      opts.fetch(:cases).each do |attribute_value, args, expected_errors|
        describe "#{method_name} when value is #{attribute_value.inspect} called with args #{args.inspect}" do
          it "results in no additional errors on the attribute and returns nil" do
            form = form_class.new(attribute_name => attribute_value)
            preceding_error = :foo
            assert_equal(false, form.any_errors?)
            form.append_error(attribute_name, preceding_error)
            assert_equal({ attribute_name => [preceding_error] }, form.errors)
            assert_equal(true, form.any_errors?)
            returned = form.validate_presence(attribute_name)
            assert_nil(returned)
            assert_equal({ attribute_name => [preceding_error] }, form.errors)
          end
        end
      end
    end

    describe "#validate_presence" do
      describe "when attribute is not present (fail validation)" do
        it_fails_validations(
          :method_name => :validate_presence,
          :attribute_name => :whatever,
          :cases => [
            ["", [], [:cant_be_empty]],
            ["", [:custom_error_message], [:custom_error_message]],
            ["     ", [], [:cant_be_empty]],
            [:"", [], [:cant_be_empty]],
            [nil, [], [:cant_be_empty]],
            [false, [], [:cant_be_empty]]
          ]
        )
      end

      describe "when attribute is present (passes validation)" do
        it_passes_validations(
          :method_name => :validate_presence,
          :attribute_name => :whatever,
          :cases => [
            ["foo", []],
            ["    foo  ", []],
            [:"foo", []],
            ["10", []],
            [5, []],
            [true, []],
            [[], []],
            [{}, []],
            [[5], []],
            [{ :foo => "bar" }, []]
          ]
        )
      end
    end

    describe "#validate_length" do
      describe "when attribute is not present (fail validation)" do
        it_fails_validations(
          :method_name => :validate_length,
          :attribute_name => :whatever,
          :cases => [
            ["", [:min => 2], [:is_too_short]],
            ["f", [:min => 2], [:is_too_short]],
            ["       ", [:max => 5], [:is_too_long]],
            [["only one element"], [:min => 2], [:is_too_short]],
            [[1, 2, 3, 4], [:max => 2], [:is_too_long]]
          ]
        )
      end

      describe "when attribute is present (passes validation)" do
        it_passes_validations(
          :method_name => :validate_length,
          :attribute_name => :whatever,
          :cases => [
            ["foo", [:min => 2]],
            ["foo", [:max => 5]],
            [["two elements", "second element"], [:min => 2]],
            [[1], [:max => 2]]
          ]
        )
      end
    end
  end
end
