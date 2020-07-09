class MoveDeconcatenatedSubjectsToSubjects < ActiveRecord::Migration[6.0]
  def change
    remove_column :items, :subject
    remove_column :theses, :subject

    
    rename_column :items, :deconcatenated_subject, :subject
    rename_column :theses, :deconcatenated_subject, :subject
  end
end
