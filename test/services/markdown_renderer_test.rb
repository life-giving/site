require "test_helper"

class MarkdownRendererTest < ActiveSupport::TestCase
  def render(text) = MarkdownRenderer.render(text)

  test "renders Markdown as safe HTML" do
    html = render("**bold**\n\n- item")

    assert_includes html, "<strong>bold</strong>"
    assert_includes html, "<li>item</li>"
    assert_predicate html, :html_safe?
  end

  test "handles a missing body" do
    assert_equal "", render(nil)
  end

  test "escapes raw HTML, inline and block" do
    html = render(%(<img src=x onerror=alert(1)>\n\n<script>alert(1)</script>\n\ntext <b onclick="x">y</b>))

    assert_not_includes html, "<img"
    assert_not_includes html, "<script"
    assert_not_includes html, "<b "
  end

  test "drops inline images" do
    assert_not_includes render("![alt](photo.png)"), "<img"
  end

  test "keeps the link text but drops unsafe schemes" do
    [ "javascript:alert(1)", "JAVASCRIPT:alert(1)", "data:text/html,x", "vbscript:x", "java\tscript:alert(1)" ].each do |href|
      html = render("[text](<#{href}>)")

      assert_includes html, "text", href
      assert_not_includes html, "<a", href
    end
  end

  test "external links open in a new tab" do
    html = render("[site](https://example.com)")

    assert_includes html, %(href="https://example.com")
    assert_includes html, %(target="_blank")
    assert_includes html, %(rel="noopener")
  end

  test "mail, phone and relative links stay in the same tab" do
    [ "mailto:a@example.org", "tel:+380961195047", "/news/1", "#about" ].each do |href|
      html = render("[text](#{href})")

      assert_includes html, %(href="#{href}"), href
      assert_not_includes html, "target=", href
    end
  end

  test "link titles and bare URLs are escaped" do
    assert_includes render(%([t](/x "a\"b<c"))), "&lt;c"
    assert_includes render("https://example.com/?a=1&b=2"), "&amp;b=2"
  end
end
