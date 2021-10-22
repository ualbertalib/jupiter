require 'test_helper'

class MarkdownTest < ActiveSupport::TestCase

  MARKDOWN = <<~MARKDOWN.freeze
    **Itaque _est_** ~~incidunt~~. Magnam *repellendus* id. Eos qui **voluptatem**.

    Here's a line for us to start with.

    This line is separated from the one above by two newlines, so it will be a *separate paragraph*.

    This line is also a separate paragraph, but...
    This line is only separated by a single newline, so it's a separate line in the *same paragraph*.

    [I'm an inline-style link with title](https://www.google.com "Google's Homepage")

    URLs and URLs in angle brackets will automatically get turned into links.
    http://www.example.com or <http://www.example.com> and sometimes
    example.com (but not on Github, for example).
  MARKDOWN

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
    item = items(:item_fancy)
    item.description = MARKDOWN

    assert_equal RENDERED_HTML, item.decorate.description
    assert_equal STRIPPED_MARKDOWN, item.decorate.plaintext_description
    assert_equal [STRIPPED_MARKDOWN],
                 item.solr_exporter.export[Item.solr_exporter_class.solr_name_for(:description, role: :search)]
  end

  test 'should render thesis abstract with markdown as html' do
    thesis = thesis(:thesis_fancy)
    thesis.abstract = MARKDOWN

    assert_equal RENDERED_HTML, thesis.decorate.abstract
    assert_equal STRIPPED_MARKDOWN, thesis.decorate.plaintext_abstract
    assert_equal [STRIPPED_MARKDOWN],
                 thesis.solr_exporter.export[Thesis.solr_exporter_class.solr_name_for(:abstract, role: :search)]
  end

  test 'should render draft description with markdown as html' do
    draft = draft_items(:draft_item_completed_describe_item_step)
    draft.description = MARKDOWN

    assert_equal RENDERED_HTML, draft.decorate.html_description
    assert_equal MARKDOWN, draft.decorate.description
  end

  test 'should render community description with markdown as html' do
    community = communities(:community_books)
    community.description = MARKDOWN

    assert_equal RENDERED_HTML, community.decorate.description
    assert_equal [STRIPPED_MARKDOWN],
                 community.solr_exporter.export[Community.solr_exporter_class.solr_name_for(:description,
                                                                                            role: :search)]
  end

  test 'should render collection description with markdown as html' do
    collection = collections(:collection_fantasy)
    collection.description = MARKDOWN

    assert_equal RENDERED_HTML, collection.decorate.description
    assert_equal [STRIPPED_MARKDOWN],
                 collection.solr_exporter.export[Collection.solr_exporter_class.solr_name_for(:description,
                                                                                              role: :search)]
  end

end
