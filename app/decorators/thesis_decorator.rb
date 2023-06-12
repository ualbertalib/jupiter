class ThesisDecorator < ApplicationDecorator

  delegate_all

  def history
    history = versions.map do |version|
      HumanizedChangeSet.new(h, version)
    end
    history.select { |humanized_change_set| humanized_change_set.html_diffs.present? }
  end

  def abstract
    render_markdown(model.abstract)
  end

  def plaintext_abstract
    strip_markdown(model.abstract)
  end

  # We want to treat thesis the same as items in a lot of cases
  # specifically when we're building links to download/view the items
  def model_name
    Item.model_name
  end

  def description
    abstract
  end

end
