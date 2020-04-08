# frozen_string_literal: true

module FontAwesomeHelper
  # Helper from Font Awesome Sass:
  # https://github.com/FortAwesome/font-awesome-sass/blob/master/lib/font_awesome/sass/rails/helpers.rb
  def icon(style, name, text = nil, html_options = {})
    if text.is_a?(Hash)
      html_options = text
      text = nil
    end

    html_options[:class] = if html_options.key?(:class)
                             "#{style} fa-#{name} #{html_options[:class]}"
                           else
                             "#{style} fa-#{name}"
                           end

    html = content_tag(:i, nil, html_options)
    html << ' ' << text.to_s if text.present?
    html
  end
end
