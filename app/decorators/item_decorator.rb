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
    strip_markdown(model.description)
  end

  def creators_label
    I18n.t('items.item.creators')
  end

  def created_label
    I18n.t('items.item.created')
  end

  def description_label
    I18n.t('items.item.description')
  end

end
