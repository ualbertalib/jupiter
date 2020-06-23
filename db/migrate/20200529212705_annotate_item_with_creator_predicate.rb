class AnnotateItemWithCreatorPredicate < ActiveRecord::Migration[6.0]
  def change
    add_rdf_table_annotations for_table: :items do |t|
      # This change removes the predicate RDF::Vocab::BIBO.authorList defined in
      # 20190926213733_annotate_tables_with_rdf
      t.creators has_predicate: ::RDF::Vocab::DC11.creator
    end
  end
end
