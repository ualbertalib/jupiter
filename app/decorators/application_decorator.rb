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

  def self.collection_decorator_class
    PaginatingDecorator
  end

  # We trust the redcarpet output which is why we think it's html_safe
  # rubocop:disable Rails/OutputSafety
  def render_markdown(text)
    html_renderer.render(text).html_safe if text.present?
  end
  # rubocop:enable Rails/OutputSafety

  def strip_markdown(text)
    strip_renderer.render(text) if text.present?
  end

  private

  def html_renderer
    renderer = Redcarpet::Render::HTML.new(Rails.configuration.markdown_rendering_options)
    @html_renderer ||= Redcarpet::Markdown.new(renderer, Rails.configuration.markdown_rendering_extensions)
  end

  def strip_renderer
    @strip_renderer ||= Redcarpet::Markdown.new(Redcarpet::Render::StripDown,
                                                Rails.configuration.markdown_rendering_extensions)
  end

end
