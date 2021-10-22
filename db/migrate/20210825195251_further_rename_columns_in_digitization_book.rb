class FurtherRenameColumnsInDigitizationBook < ActiveRecord::Migration[6.0]
  def change
    add_reference :digitization_books, :logo, foreign_key: {to_table: :active_storage_attachments, column: :id, on_delete: :nullify}

    delete_column_annotation :digitization_books, :alternative_title
    add_rdf_column_annotation :digitization_books, :alternative_titles, has_predicate: ::RDF::Vocab::DC.alternative

    delete_column_annotation :digitization_books, :rights
    add_rdf_column_annotation :digitization_books, :rights, has_predicate: ::RDF::Vocab::EDM.rights
  end
end
