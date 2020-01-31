class Metadata::OaiDc::ItemDecorator < Draper::Decorator
  delegate :title, :publisher, :subject, :description

  def creator
    object.creators
  end

  def contributor
    object.contributors
  end

  def rights
    if object.license.present?
      h.humanize_uri(:license, object.license)
    else
      object.rights
    end
  end

  def identifier
    [h.item_url(object), object.doi]
  end

  def date
    object.creation_date
  end
end
