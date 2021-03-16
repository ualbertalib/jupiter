require 'redcarpet'

module MarkdownDecorator
  options = {
    filter_html: true,
    no_images: true,
    no_styles: true,
    hard_wrap: true,
    link_attributes: { rel: 'noopener noreferrer', target: '_blank' }
  }

  extensions = {
    lax_spacing: true,
    strikethrough: true,
    fenced_code_blocks: true,
    tables: true,
    autolink: true
  }

  renderer = Redcarpet::Render::HTML.new(options)
  RenderMarkdown = Redcarpet::Markdown.new(renderer, extensions)

  # We trust the redcarpet output which is why we think it's html_safe
  # rubocop:disable Rails/OutputSafety
  def markdown(text)
    RenderMarkdown.render(text).html_safe if text.present?
  end
  # rubocop:enable Rails/OutputSafety
end
