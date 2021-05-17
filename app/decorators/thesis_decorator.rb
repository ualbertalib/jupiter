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

  def creators
    [model.dissertant]
  end

  def creators_label
    I18n.t('items.thesis.dissertant')
  end

  def description
    model.abstract
  end

  def description_label
    I18n.t('items.thesis.abstract')
  end

  def created_label
    I18n.t('items.thesis.graduation_date')
  end

  def all_subjects
    subject
  end

  def license
    rights
  end

  def languages
    [language]
  end

end
