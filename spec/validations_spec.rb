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
    describe "#validate_presence" do
      describe "when attribute is not present (fail validation)" do
        {
          "" => [:cant_be_empty],
          "     " => [:cant_be_empty],
          :"" => [:cant_be_empty],
          nil => [:cant_be_empty],
          false => [:cant_be_empty]
        }.each do |attribute_value, expected_errors|
          describe "when value is #{attribute_value.inspect}" do
            it "results in errors #{expected_errors.inspect} on the attribute and returns all the errors on the attribute" do
              form = form_class.new(:whatever => attribute_value)
              preceding_error = :is_invalid
              assert_equal(false, form.any_errors?)
              form.append_error(:whatever, preceding_error)
              assert_equal({ :whatever => [preceding_error] }, form.errors)
              assert_equal(true, form.any_errors?)
              returned = form.validate_presence(:whatever)
              assert_equal([preceding_error] + expected_errors, returned)
              assert_equal({ :whatever => [preceding_error] + expected_errors }, form.errors)
            end
          end
        end
      end

      describe "when attribute is present (passes validation)" do
        [
          "foo",
          "    foo  ",
          :"foo",
          "10",
          5,
          true,
          [],
          {},
          [5],
          { :foo => "bar" }
        ].each do |attribute_value|
          describe "when value is #{attribute_value.inspect}" do
            it "results in no additional errors on the attribute and returns nil" do
              form = form_class.new(:whatever => attribute_value)
              preceding_error = :is_invalid
              assert_equal(false, form.any_errors?)
              form.append_error(:whatever, preceding_error)
              assert_equal({ :whatever => [preceding_error] }, form.errors)
              assert_equal(true, form.any_errors?)
              returned = form.validate_presence(:whatever)
              assert_nil(returned)
              assert_equal({ :whatever => [preceding_error] }, form.errors)
            end
          end
        end
      end
    end
  end
end
