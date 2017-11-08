require_relative "../spec_helper"

describe Gourami::Extensions::Changes do
  describe "#changes?" do
    describe "when the provided attribute is not watching changes" do
      let(:form_class) do
        Class.new(Gourami::Form).tap do |form|
          form.send(:include, Gourami::Extensions::Changes)
          form.attribute(:bar)
        end
      end

      it "raises a NotWatchingChangesError on initialize" do
        form = form_class.new
        assert_raises(Gourami::NotWatchingChangesError) do
          form.changes?(:bar)
        end
      end

      it "does not raise a NotWatchingChangesError if set manually" do
        form = form_class.new
        form.send(:changed_attributes)[:bar] = true
        assert_equal(true, form.changes?(:bar))
      end
    end

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

        it "when the attribute is provided in its writer and is the same it returns false" do
          record = OpenStruct.new(:bar => "baz")
          form = form_class.new
          form.foo = record
          form.bar = "baz"
          assert_equal(false, form.changes?(:bar))
        end

        it "when the attribute is provided in its writer and is different it returns true" do
          record = OpenStruct.new(:bar => "baz")
          form = form_class.new
          form.foo = record
          form.bar = "something else"
          assert_equal(true, form.changes?(:bar))
        end

        it "when the attribute is changed multiple times and ends up being different it returns true" do
          record = OpenStruct.new(:bar => "baz")
          form = form_class.new
          form.foo = record
          form.bar = "baz"
          form.bar = "something else"
          assert_equal(true, form.changes?(:bar))
        end

        it "when the attribute is changed multiple times and ends up being the same it returns false" do
          record = OpenStruct.new(:bar => "baz")
          form = form_class.new
          form.foo = record
          form.bar = "something else"
          form.bar = "baz"
          assert_equal(false, form.changes?(:bar))
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

    describe "watch_changes can apply other changes too" do
      describe "when calling did_change with default 2nd argument" do
        let(:form_class) do
          Class.new(Gourami::Form).tap do |form|
            form.send(:include, Gourami::Extensions::Changes)
            form.attribute(:bar, :watch_changes => ->(new_value) {
              did_change(:baz)

              false
            })
          end
        end

        it "returns true for the side effect" do
          form = form_class.new

          assert_equal(true, form.changes?(:baz))
          assert_equal(false, form.changes?(:bar))
        end
      end

      describe "when calling did_change with `false` as 2nd argument" do
        let(:form_class) do
          Class.new(Gourami::Form).tap do |form|
            form.send(:include, Gourami::Extensions::Changes)
            form.attribute(:foo, :watch_changes => ->(_new_value) { true })
            form.attribute(:bar, :watch_changes => ->(_new_value) {
              did_change(:foo, false)

              false
            })
          end
        end

        it "returns true for the side effect" do
          form = form_class.new

          assert_equal(false, form.changes?(:foo))

          form.foo = "foo"
          assert_equal(true, form.changes?(:foo))

          form.bar = "bar"
          assert_equal(false, form.changes?(:foo))
        end
      end

      describe "when the order is reversed" do
        let(:form_class) do
          Class.new(Gourami::Form).tap do |form|
            form.send(:include, Gourami::Extensions::Changes)
            form.attribute(:bar, :watch_changes => ->(_new_value) {
              did_change(:foo, false)

              false
              })
            form.attribute(:foo, :watch_changes => ->(_new_value) { true })
          end
        end

        it "the last defined attribute is the one used when mass-assigning attributes like with initialize or set_attributes" do
          form = form_class.new

          assert_equal(true, form.changes?(:foo))

          form.foo = "foo"
          assert_equal(true, form.changes?(:foo))

          form.bar = "bar"
          assert_equal(false, form.changes?(:foo))
        end
      end
    end

    describe "when type coercing is required" do
      it "coerces attribute value before passing it to watch_changes" do
        new_value_class = nil
        form_class = Class.new(Gourami::Form).tap do |form|
          form.send(:include, Gourami::Extensions::Changes)
          form.send(:include, Gourami::Coercer)
          form.attribute(:foo, :type => :integer, :watch_changes => ->(new_value) {
            new_value_class = new_value.class

            false
          })
        end

        form = form_class.new(:foo => "12345")
        assert_equal(Fixnum, new_value_class)
      end
    end
  end
end
