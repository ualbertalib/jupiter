class Digitization::NewspaperDecorator < ApplicationDecorator

  delegate_all

  def all_subjects
    object.geographic_subjects
  end

  def each_community_collection
    # TODO: remove when Digitization collection is completed
    []
  end

  def alternative_title
    object.alternative_titles.join(' ') if object.alternative_titles.present?
  end

  def description
    object.notes.join(' ') if object.notes.present?
  end

  def creation_date
    object.dates_issued.first if object.dates_issued.present?
  end

  def sort_year
    # TODO: remove when sort_year has been added
    nil
  end

  def volume_label
    "#{object.volume} #{object.issue}"
  end

  def languages
    object.languages.map { |language| h.humanize_uri(:digitization, :language, language) }
  end

end
