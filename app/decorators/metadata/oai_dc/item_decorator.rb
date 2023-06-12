class Metadata::OaiDc::ItemDecorator < ApplicationDecorator

  delegate :description, :publisher, :subject, :title, :updated_at

  def creator
    object.creators
  end

  def contributor
    object.contributors
  end

  def rights
    object.license.presence || object.rights
  end

  def identifiers
    [item_url(object), object.doi]
  end

  def date
    object.creation_date
  end

  def type
    I18n.t("controlled_vocabularies.era.item_type_with_status.#{object.item_type_with_status_code}")
  end

  def languages
    object.languages.map { |l| h.humanize_uri(:era, :language, l) }
  end

end
