class AddVolumeLabelToDigitizationBook < ActiveRecord::Migration[6.0]
  def change
    add_column :digitization_books, :volume_label, :string
    add_rdf_column_annotation :digitization_books, :volume_label, has_predicate: ::TERMS[:rdfs].ch_label
  end
end
