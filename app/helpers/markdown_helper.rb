module MarkdownHelper
  def markdown(text)
    Jupiter::RenderMarkdown.render(text).html_safe
  rescue StandardError
    text.html_safe
  end

  def strip_markdown(text)
    Jupiter::StripMarkdown.render(text).html_safe
  rescue StandardError
    text.html_safe
  end
end
