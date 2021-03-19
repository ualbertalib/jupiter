require 'test_helper'

class MarkdownTest < ActiveSupport::TestCase

  # rubocop:disable Layout/TrailingWhitespace
  RENDERED_HTML = <<~RENDERED.freeze
    <p><strong>Itaque <em>est</em></strong> <del>incidunt</del>. Magnam <em>repellendus</em> id. Eos qui <strong>voluptatem</strong>.</p>
    
    <p>Here&#39;s a line for us to start with.</p>
    
    <p>This line is separated from the one above by two newlines, so it will be a <em>separate paragraph</em>.</p>
   
    <p>This line is also a separate paragraph, but...<br>
    This line is only separated by a single newline, so it&#39;s a separate line in the <em>same paragraph</em>.</p>
  
    <p><a href=\"https://www.google.com\" title=\"Google&#39;s Homepage\" rel=\"noopener noreferrer\" target=\"_blank\">I&#39;m an inline-style link with title</a></p>
    
    <p>URLs and URLs in angle brackets will automatically get turned into links.<br>
    <a href=\"http://www.example.com\" rel=\"noopener noreferrer\" target=\"_blank\">http://www.example.com</a> or <a href=\"http://www.example.com\" rel=\"noopener noreferrer\" target=\"_blank\">http://www.example.com</a> and sometimes<br>
    example.com (but not on Github, for example).</p>
  RENDERED
  # rubocop:enable Layout/TrailingWhitespace

  STRIPPED_MARKDOWN = <<~STRIPPED.freeze
    Itaque est incidunt. Magnam repellendus id. Eos qui voluptatem.
    Here's a line for us to start with.
    This line is separated from the one above by two newlines, so it will be a separate paragraph.
    This line is also a separate paragraph, but...
    This line is only separated by a single newline, so it's a separate line in the same paragraph.
    I'm an inline-style link with title (https://www.google.com)
    URLs and URLs in angle brackets will automatically get turned into links.
    http://www.example.com or http://www.example.com and sometimes
    example.com (but not on Github, for example).
  STRIPPED

  test 'should render item description with markdown as html' do
    item = items(:markdown_item)

    assert_equal RENDERED_HTML, item.decorate.description
    assert_equal [STRIPPED_MARKDOWN],
                 item.solr_exporter.export[Item.solr_exporter_class.solr_name_for(:description, role: :search)]
  end

  test 'thesis abstract' do
    thesis = thesis(:markdown)

    assert_equal RENDERED_HTML, thesis.decorate.abstract
    assert_equal [STRIPPED_MARKDOWN],
                 thesis.solr_exporter.export[Thesis.solr_exporter_class.solr_name_for(:abstract, role: :search)]
  end
end
