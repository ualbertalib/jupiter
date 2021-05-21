class Digitization::BookDecorator < ApplicationDecorator

  delegate_all

  def subject
    object.topical_subject
  end

  def copyright
    object.rights
  end

  def files
    nil
  end

  def each_community_collection
    []
  end

  def alternative_title
    object.alt_title.join(' ')
  end

  def creators
    object.publisher.map {|contributor| h.humanize_uri(:digitization, :subject, contributor)}
  end

  def description
    object.note.join(' ')
  end

  def solr_exporter_class
    Exporters::Solr::Digitization::BookExporter
  end

  def creation_date
    object.date_issued.first
  end

  def sort_year
    false
  end

  def all_subjects
    object.topical_subject + object.temporal_subject + object.geographic_subject
  end

  def item_type_with_status_code
    false
  end

  def doi
    false
  end

  def languages
    object.language.map {|language| h.humanize_uri(:digitization, :language, language)}
  end

  def contributors
    object.publisher.map {|contributor| h.humanize_uri(:digitization, :subject, contributor)}
  end

  def is_version_of
    false
  end

  def source
    false
  end

  def related_link
    false
  end

  def volume_label
    'v. 2'
  end
end
