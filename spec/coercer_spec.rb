require_relative "./spec_helper"

describe Gourami::Coercer do
  let(:coercer) { Class.new.extend(Gourami::Coercer) }

  describe "#coerce_string" do
    describe "options" do
      describe ":allow_nil" do
        it "when not provided returns nil" do
          assert_nil(coercer.coerce_string(nil))
        end

        it "when true returns nil" do
          assert_nil(coercer.coerce_string(nil, :allow_nil => true))
        end

        it "when false converts to string" do
          assert_equal("", coercer.coerce_string(nil, :allow_nil => false))
        end
      end
    end
  end

  describe "#coerce_array" do
    describe "options" do
      let(:coercer_options) { { :element_type => element_type } }

      let(:coercer_value) { {
        12345 => {
          :key => :value
        }
      } }

      subject { coercer.coerce_array(coercer_value, coercer_options) }

      describe "when :element_type is a Symbol" do
        let(:element_type) { :hash }

        it "converts to an Array but does not coerce :key_type or :value_type" do
          expected = [{
            :key => :value
          }]
          assert_equal(expected, subject)
        end
      end

      describe "when :element_type is a Hash" do
        let(:element_type) { {
          :type => :hash, :key_type => :string, :value_type => :string
        } }

        it "uses the :key_type and :value_type options to each child" do
          expected = [{
            "key" => "value"
          }]
          assert_equal(expected, subject)
        end
      end
    end
  end
end
