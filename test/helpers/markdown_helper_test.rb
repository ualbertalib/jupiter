require 'test_helper'

class MarkdownHelperTest < ActionView::TestCase

  include Webpacker::Helper

  # we are testing by requirement in #1322
  # - bold/strong text highlighting
  # - italics
  # - line breaks
  # - paragraphs
  # - links
  # but some others too that came from Faker::Markdown.sandwich
  # - headers
  # - code
  # - ordered and unordered lists
  # - tables
  RAW_MARKDOWN = <<~MARKDOWN.freeze
    ##### Et
    **Itaque _est_** ~~incidunt~~. Magnam *repellendus* id. Eos qui **voluptatem**.

    Here's a line for us to start with.

    This line is separated from the one above by two newlines, so it will be a *separate paragraph*.

    This line is also a separate paragraph, but...
    This line is only separated by a single newline, so it's a separate line in the *same paragraph*.

    [I'm an inline-style link with title](https://www.google.com "Google's Homepage")

    URLs and URLs in angle brackets will automatically get turned into links.
    http://www.example.com or <http://www.example.com> and sometimes
    example.com (but not on Github, for example).

    ```ruby
    Mollitia.
    ```

    sed | autem | illo
    ---- | ---- | ----
    magnam | voluptatibus | sint
    totam | pariatur | nulla

    1. Dolorum.
      1. Reiciendis.
    1. Iusto.
    1. Saepe.

    * Dolore.
      * Eos.
    * Eos.
    * Facere.
    * Qui.
    * Qui.
  MARKDOWN

  test 'should render markdown as html' do
    rendered_html = <<~RENDERED
            <h5>Et</h5>
      #{'            '}
            <p><strong>Itaque <em>est</em></strong> <del>incidunt</del>. Magnam <em>repellendus</em> id. Eos qui <strong>voluptatem</strong>.</p>
      #{'      '}
            <p>Here&#39;s a line for us to start with.</p>
      #{'      '}
            <p>This line is separated from the one above by two newlines, so it will be a <em>separate paragraph</em>.</p>
      #{'            '}
            <p>This line is also a separate paragraph, but...<br>
            This line is only separated by a single newline, so it&#39;s a separate line in the <em>same paragraph</em>.</p>
      #{'            '}
            <p><a href=\"https://www.google.com\" title=\"Google&#39;s Homepage\" rel=\"noopener noreferrer\" target=\"_blank\">I&#39;m an inline-style link with title</a></p>
      #{'            '}
            <p>URLs and URLs in angle brackets will automatically get turned into links. <br>
            <a href=\"http://www.example.com\" rel=\"noopener noreferrer\" target=\"_blank\">http://www.example.com</a> or <a href=\"http://www.example.com\" rel=\"noopener noreferrer\" target=\"_blank\">http://www.example.com</a> and sometimes <br>
            example.com (but not on Github, for example).</p>
      #{'            '}
            <pre><code class=\"ruby\">Mollitia.
            </code></pre>
      #{'      '}
            <table><thead>
            <tr>
            <th>sed</th>
            <th>autem</th>
            <th>illo</th>
            </tr>
            </thead><tbody>
            <tr>
            <td>magnam</td>
            <td>voluptatibus</td>
            <td>sint</td>
            </tr>
            <tr>
            <td>totam</td>
            <td>pariatur</td>
            <td>nulla</td>
            </tr>
            </tbody></table>
      #{'      '}
            <ol>
            <li>Dolorum.
      #{'      '}
            <ol>
            <li>Reiciendis.</li>
            </ol></li>
            <li>Iusto.</li>
            <li>Saepe. </li>
            </ol>
      #{'      '}
            <ul>
            <li>Dolore.
      #{'            '}
            <ul>
            <li>Eos.</li>
            </ul></li>
            <li>Eos.</li>
            <li>Facere.</li>
            <li>Qui.</li>
            <li>Qui. </li>
            </ul>
    RENDERED

    assert_equal rendered_html, markdown(RAW_MARKDOWN)
  end

  test 'should strip markdown from text' do
    stripped_text = <<~STRIPPED
            Et
            Itaque est ~~incidunt~~. Magnam repellendus id. Eos qui voluptatem.
            Here's a line for us to start with.
            This line is separated from the one above by two newlines, so it will be a separate paragraph.
            This line is also a separate paragraph, but...
            This line is only separated by a single newline, so it's a separate line in the same paragraph.
            I'm an inline-style link with title (https://www.google.com)
            URLs and URLs in angle brackets will automatically get turned into links.
            http://www.example.com or http://www.example.com and sometimes
            example.com (but not on Github, for example).
            ruby
            Mollitia.
      #{'      '}
            sed | autem | illo
            ---- | ---- | ----
            magnam | voluptatibus | sint
            totam | pariatur | nulla
            Dolorum.
            Reiciendis.
            Iusto.
            Saepe.
            Dolore.
            Eos.
            Eos.
            Facere.
            Qui.
            Qui.
    STRIPPED

    assert_equal stripped_text, strip_markdown(RAW_MARKDOWN)
  end

end
