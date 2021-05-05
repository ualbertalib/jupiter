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

  def all_subjects
    model.subject
  end

  def languages
    [model.language]
  end

end
