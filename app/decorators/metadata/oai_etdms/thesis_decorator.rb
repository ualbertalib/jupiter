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
    I18n.t("controlled_vocabularies.item_type_with_status.#{object.item_type_with_status_code}")
  end

  def date
    # TODO: need to talk to metadata about fallback if date accepted is not present, which it isn't for legacy theses
    object.date_accepted || object.created_at
  end

  def date_etdms
    # use graduation date which is a required property with formats `YYYY`, `Fall YYYY`, `Spring YYYY`, or `YYYY-MM`
    # convert to LAC etdms format `YYYY` or `YYYY-MM`: https://www.bac-lac.gc.ca/eng/services/theses/Pages/universities.aspx
    regex = /
              (?<season>
                #{I18n.t('items.thesis.graduation_terms.fall')}
                |
                #{I18n.t('items.thesis.graduation_terms.spring')}
              )? # capture fall or spring, e.g., Fall 2010
              [ ]?
              (?<year>\d{4})(?<mm_dd>-\d{2})? # capture YYYY and numeric month, if present
            /x

    capture = object.graduation_date.match(regex)

    throw ArgumentError() if capture.nil? || capture[:year].nil?

    case capture[:season]
    when I18n.t('items.thesis.graduation_terms.fall')
      "#{capture[:year]}-#{I18n.t('items.thesis.graduation_terms.fall_num')}"
    when I18n.t('items.thesis.graduation_terms.spring')
      "#{capture[:year]}-#{I18n.t('items.thesis.graduation_terms.spring_num')}"
    else
      "#{capture[:year]}#{capture[:mm_dd]}"
    end
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
    h.humanize_uri(:language, object.language)
  end

  def degree_level
    object.thesis_level
  end

  def discipline
    object.departments&.first
  end

  def institution
    # TODO: Replace Unknown with appropriate tag from metadata team
    h.humanize_uri(:institution, object.institution) || 'Unknown'
  end

  def degree_name
    # TODO: Replace Unknown with appropriate tag from metadata team
    object.degree.presence || 'Unknown'
  end

  def publisher
    # TODO: Replace Unknown with appropriate tag from metadata team
    h.humanize_uri(:institution, object.institution) || 'Unknown'
  end

end
