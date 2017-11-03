require_relative "../spec_helper"

describe Gourami::Extensions::Changes do
  describe "#changes?" do
    describe ":watch_changes => true" do
      describe "when there is a record" do
        let(:form_class) do
          Class.new(Gourami::Form).tap do |form|
            form.send(:include, Gourami::Extensions::Changes)
            form.record(:foo)
            form.attribute(:bar, :watch_changes => true)
          end
        end

        it "when the attribute is provided in initialize and is the same it returns false" do
          record = OpenStruct.new(:bar => "baz")
          form = form_class.new(:bar => "baz", :foo => record)
          assert_equal(false, form.changes?(:bar))
        end

        it "when the attribute is provided in initialize and is different it returns true" do
          record = OpenStruct.new(:bar => "baz")
          form = form_class.new(:bar => "something else", :foo => record)
          assert_equal(true, form.changes?(:bar))
        end

        it "when the attribute is provided in set_attributes and is the same it returns false" do
          record = OpenStruct.new(:bar => "baz")
          form = form_class.new
          form.set_attributes(:bar => "baz", :foo => record)
          assert_equal(false, form.changes?(:bar))
        end

        it "when the attribute is provided in set_attributes and is different it returns true" do
          record = OpenStruct.new(:bar => "baz")
          form = form_class.new
          form.set_attributes(:bar => "something else", :foo => record)
          assert_equal(true, form.changes?(:bar))
        end

        it "when the attribute is not provided and record has a value for the attribute it returns true" do
          record = OpenStruct.new(:bar => "baz")
          form = form_class.new(:foo => record)
          assert_equal(true, form.changes?(:bar))
        end

        it "when the attribute is not provided and record has no value either it returns false" do
          record = OpenStruct.new(:bar => nil)
          form = form_class.new(:foo => record)
          assert_equal(false, form.changes?(:bar))
        end

        it "when the attribute is provided and record is defined but not present it returns true" do
          form = form_class.new(:bar => "baz")
          assert_equal(true, form.changes?(:bar))
        end

        it "when the attribute is not provided and record is defined but not present it returns false" do
          form = form_class.new
          assert_equal(false, form.changes?(:bar))
        end
      end

      describe "when there is no record" do
        let(:form_class) do
          Class.new(Gourami::Form).tap do |form|
            form.send(:include, Gourami::Extensions::Changes)
            form.attribute(:bar, :watch_changes => true)
          end
        end

        it "raises a configuration exception on initialize" do
          assert_raises(Gourami::ConfigurationError) do
            form_class.new
          end
        end
      end
    end

    describe ":watch_changes => ->(new_value) { custom_logic }" do
      let(:form_class) do
        Class.new(Gourami::Form).tap do |form|
          form.send(:include, Gourami::Extensions::Changes)
          form.attribute(:foo, :skip => true)
          form.attribute(:bar, :watch_changes => ->(new_value) { !!foo && foo.bar != new_value })
        end
      end

      it "when the attribute is provided in initialize and is the same" do
        record = OpenStruct.new(:bar => "baz")
        form = form_class.new(:foo => record, :bar => "baz")
        assert_equal(false, form.changes?(:bar))
      end

      it "when the attribute is provided in initialize and is different" do
        record = OpenStruct.new(:bar => "baz")
        form = form_class.new(:foo => record, :bar => "something else")
        assert_equal(true, form.changes?(:bar))
      end

      it "when the attribute is provided in set_attributes and is the same" do
        record = OpenStruct.new(:bar => "baz")
        form = form_class.new
        form.set_attributes(:foo => record, :bar => "baz")
        assert_equal(false, form.changes?(:bar))
      end

      it "when the attribute is provided in set_attributes and is different" do
        record = OpenStruct.new(:bar => "baz")
        form = form_class.new
        form.set_attributes(:foo => record, :bar => "something else")
        assert_equal(true, form.changes?(:bar))
      end

      it "when the attribute is not provided and record has a value for the attribute" do
        record = OpenStruct.new(:bar => "baz")
        form = form_class.new(:foo => record)
        assert_equal(true, form.changes?(:bar))
      end

      it "when the attribute is not provided and record has no value either" do
        record = OpenStruct.new(:bar => nil)
        form = form_class.new(:foo => record)
        assert_equal(false, form.changes?(:bar))
      end

      it "does not raise an exception on initialize" do
        form_class.new
      end
    end

  end
end
