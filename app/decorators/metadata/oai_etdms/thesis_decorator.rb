class Metadata::OaiEtdms::ThesisDecorator < ApplicationDecorator

  delegate :degree, :subject, :title, :updated_at

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
    I18n.t("controlled_vocabularies.era.item_type_with_status.#{object.item_type_with_status_code}")
  end

  def date
    object.graduation_date
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

  delegate :rights, to: :object

  def language
    h.humanize_uri(:era, :language, object.language)
  end

  def degree_level
    object.thesis_level
  end

  def discipline
    object.departments&.first
  end

  def institution
    # TODO: Replace Unknown with appropriate tag from metadata team
    h.humanize_uri(:era, :institution, object.institution) || 'Unknown'
  end

  def degree_name
    # TODO: Replace Unknown with appropriate tag from metadata team
    object.degree.presence || 'Unknown'
  end

  def publisher
    # TODO: Replace Unknown with appropriate tag from metadata team
    h.humanize_uri(:era, :institution, object.institution) || 'Unknown'
  end

end
