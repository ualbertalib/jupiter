class ItemDecorator < ApplicationDecorator

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

  def plain_description
    strip_markdown(model.description)
  end

end
