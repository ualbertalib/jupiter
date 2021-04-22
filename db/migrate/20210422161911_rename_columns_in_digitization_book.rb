class RenameColumnsInDigitizationBook < ActiveRecord::Migration[6.0]
  def change
    change_table :digitization_books do |t|
      t.rename :alt_title, :alternative_titles
      t.rename :language, :languages
      t.rename :date_issued, :dates_issued
      t.rename :temporal_subject, :temporal_subjects
      t.rename :genre, :genres
      t.rename :publisher, :publishers
      t.rename :place_of_publication, :places_of_publication
      t.rename :note, :notes
      t.rename :geographic_subject, :geographic_subjects
      t.rename :topical_subject, :topical_subjects
    end
  end
end
