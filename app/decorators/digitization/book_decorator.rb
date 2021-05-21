class Digitization::BookDecorator < ApplicationDecorator

  delegate_all

  def subject
    object.topical_subjects
  end

  def copyright
    object.rights
  end

  def each_community_collection
    []
  end

  def alternative_title
    object.alternative_titles.join(' ') if object.alternative_titles.present?
  end

  def creators
    return if object.publishers.blank?

    object.publishers.map { |contributor| h.humanize_uri(:digitization, :subject, contributor) }
  end

  def description
    object.notes.join(' ') if object.notes.present?
  end

  def solr_exporter_class
    Exporters::Solr::Digitization::BookExporter
  end

  def creation_date
    object.dates_issued.first if object.dates_issued.present?
  end

  def all_subjects
    object.topical_subjects + object.temporal_subjects + object.geographic_subjects
  end

  def languages
    object.languages.map { |language| h.humanize_uri(:digitization, :language, language) }
  end

  def contributors
    object.publisher.map { |contributor| h.humanize_uri(:digitization, :subject, contributor) }
  end

  def sort_year
    # TODO: remove when sort_year has been added
    nil
  end

  def files
    # TODO: remove when `has_many_attached :files, dependent: false` is added to the Book model
    nil
  end

end
