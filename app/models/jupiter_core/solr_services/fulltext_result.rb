class JupiterCore::SolrServices::FulltextResult

  attr_reader :highlight_text

  def initialize(highlight_text:)
    @highlight_text = highlight_text
  end

  def to_partial_path
    'fulltext_result'
  end

end
