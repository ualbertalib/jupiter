class ItemDecorator < Draper::Decorator

  include MarkdownDecorator

  delegate_all

  def history
    history = versions.map do |version|
      HumanizedChangeSet.new(h, version)
    end
    history.select { |humanized_change_set| humanized_change_set.html_diffs.present? }
  end

  def description
    markdown(model.description)
  end

end
