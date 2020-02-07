class Metadata::OaiEtdms::ThesisDecorator < ApplicationDecorator
  delegate :subject, :title, :updated_at

  def creator
    object.dissertant
  end

  def description
    "Abstract: #{object.abstract}" if object.abstract.present?
  end

  def contributor
    object.supervisors
  end

  def type
    I18n.t("controlled_vocabularies.item_type_with_status.#{object.item_type_with_status_code}")
  end

  def date
    # TODO need to talk to metadata about fallback if date accepted is not present, which it isn't for legacy theses
    object.date_accepted || object.created_at
  end

  def identifiers
    files = object.files.map do |file|
      # LAC requires that there be no spaces in the URL, for whatever questionable reasons
      file_view_item_url(id: file.record.id,
                         file_set_id: file.fileset_uuid,
                         file_name: file.filename.to_s).tr(' ', '_')
    end
    [item_url(object), object.doi, files].flatten
  end

  def rights
    object.rights
  end

  def language
    h.humanize_uri(:language, object.language)
  end

end
