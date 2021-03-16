class ThesisDecorator < Draper::Decorator

  include MarkdownDecorator

  delegate_all

  def history
    history = versions.map do |version|
      HumanizedChangeSet.new(h, version)
    end
    history.select { |humanized_change_set| humanized_change_set.html_diffs.present? }
  end

  def abstract
    markdown(model.abstract)
  end

end
