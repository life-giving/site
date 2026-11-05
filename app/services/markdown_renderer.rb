# Markdown to HTML for news bodies and the editor preview. Raw HTML is escaped, inline images
# are dropped (galleries hold the photos), and links are limited to safe schemes.
class MarkdownRenderer
  EXTENSIONS = { autolink: true, strikethrough: true, tables: true, no_intra_emphasis: true }.freeze

  class SafeHtml < Redcarpet::Render::HTML
    ALLOWED_SCHEME = /\A(?:https?:|mailto:|tel:)/i
    ANY_SCHEME = /\A[a-z][a-z0-9+.-]*:/i
    EXTERNAL = /\Ahttps?:/i

    def image(*)
      ""
    end

    def link(href, title, content)
      return content unless safe?(href)

      attributes = { href: href, title: title.presence }
      attributes.update(target: "_blank", rel: "noopener") if href.to_s.match?(EXTERNAL)
      ActionController::Base.helpers.tag.a(content.to_s.html_safe, **attributes.compact)
    end

    def autolink(url, type)
      link(type == :email ? "mailto:#{url}" : url, nil, ERB::Util.html_escape(url))
    end

    private

    # Browsers ignore whitespace and control characters in a scheme: "java\tscript:".
    def safe?(href)
      compact = href.to_s.gsub(/[\u0000- ]/, "")
      compact.match?(ALLOWED_SCHEME) || !compact.match?(ANY_SCHEME)
    end
  end

  def self.render(text)
    # A new parser per call: Redcarpet parsers aren't safe to share between threads.
    Redcarpet::Markdown.new(SafeHtml.new(escape_html: true), EXTENSIONS).render(text.to_s).html_safe
  end
end
