require_relative "../spec_helper"

describe "Gourami::Plugins::Sanitize" do
  let(:form_class) do
    Class.new(Gourami::Form) do
      plugin :sanitize

      attribute :bio, :type => :sanitized_string
    end
  end

  it "removes dangerous html tags" do
    form = form_class.new(:bio => "<script>alert('xss')</script><p>foo</p>")

    assert_equal("<p>foo</p>", form.bio)
  end

  it "removes unescaped characters and removes dangerous html tags" do
    form = form_class.new(:bio => "&lt;p&gt;Hello &amp; welcome!&lt;img src=a onerror=alert(1)&gt;&lt;/p&gt;")

    assert_equal("<p>Hello & welcome!<img src=\"a\"></p>", form.bio)
  end

  it "returns nil for nil, same as coerce_string" do
    form = form_class.new(:bio => nil)

    assert_nil(form.bio)
  end

  it "strips html-entity-encoded script tags, loofah by itself would leave intact as text" do
    # Without unescaping first, Loofah sees "&lt;script&gt;" as normal text (not a tag) and passes it through unchanged.
    # If something downstream later unescapes that "safe" output, the entities turn back into a live <script> tag and the XSS executes.
    form = form_class.new(:bio => "&lt;script&gt;alert('xss')&lt;/script&gt;")

    assert_equal("", form.bio)
  end
end
