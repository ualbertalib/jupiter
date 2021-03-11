require 'redcarpet'
require 'redcarpet/render_strip'

module Jupiter
  options = {
    filter_html: true,
    no_images: true,
    no_styles: true,
    hard_wrap: true,
    link_attributes: { rel: 'noopener noreferrer', target: '_blank' }
  }

  extensions = {
    lax_spacing: true,
    fenced_code_blocks: true,
    tables: true,
    autolink: true
  }

  StripMarkdown = Redcarpet::Markdown.new(Redcarpet::Render::StripDown)

  renderer = Redcarpet::Render::HTML.new(options)
  RenderMarkdown = Redcarpet::Markdown.new(renderer, extensions)
end
