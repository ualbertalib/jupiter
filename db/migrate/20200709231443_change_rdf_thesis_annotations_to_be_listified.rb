class ChangeRdfThesisAnnotationsToBeListified < ActiveRecord::Migration[6.0]
  def change
    add_rdf_table_annotations for_table: :theses do |t|
      # This change replaces the predicates TERMS[:ual].department_list and
      # TERMS[:ual].supervisor_list defined in
      # 20190926213733_annotate_tables_with_rdf
      t.departments has_predicate: TERMS[:ual].department
      t.supervisors has_predicate: TERMS[:ual].supervisor
    end
  end
end
