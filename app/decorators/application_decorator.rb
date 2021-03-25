require 'redcarpet'
class ApplicationDecorator < Draper::Decorator

  # see https://github.com/drapergem/draper/issues/859 for why we never want to NOT
  # delgate the id method
  delegate :id

  # URL Helpers. Normally you can access through the viewcontext via +h.helper_method+, BUT
  # this comes with the caveat that the URL helpers the viewcontext can *see* depends on what
  # engine the decorator is run from, which leads to varying and unpredictable behaviour of
  # decorated methods involving paths. By directly importing the Rails application instance's
  # URL helpers, we can ensure the decorated methods behave consistently.
  include Rails.application.routes.url_helpers

  options = {
    filter_html: true,
    no_images: true,
    no_styles: true,
    hard_wrap: true,
    link_attributes: { rel: 'noopener noreferrer', target: '_blank' }
  }

  renderer = Redcarpet::Render::HTML.new(options)
  RenderMarkdown = Redcarpet::Markdown.new(renderer, Rails.configuration.markdown_rendering_extensions)

  # We trust the redcarpet output which is why we think it's html_safe
  # rubocop:disable Rails/OutputSafety
  def markdown(text)
    RenderMarkdown.render(text).html_safe if text.present?
  end
  # rubocop:enable Rails/OutputSafety

end
