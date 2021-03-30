class ItemDecorator < ApplicationDecorator

  delegate_all

  def history
    history = versions.map do |version|
      HumanizedChangeSet.new(h, version)
    end
    history.select { |humanized_change_set| humanized_change_set.html_diffs.present? }
  end

  def description
    render_markdown(model.description)
  end

  def plaintext_description
    unrender_markdown(model.description)
  end

end
