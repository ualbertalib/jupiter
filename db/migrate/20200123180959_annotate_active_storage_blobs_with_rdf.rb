class AnnotateActiveStorageBlobsWithRdf < ActiveRecord::Migration[5.2]

  def change
    add_rdf_table_annotations for_table: :active_storage_blobs do |t|
      t.filename has_predicate: ::RDF::Vocab::EBUCore.filename
      t.content_type has_predicate: ::RDF::Vocab::EBUCore.hasMimeType
      t.byte_size has_predicate: ::RDF::Vocab::PREMIS.hasSize
      t.checksum has_predicate: ::RDF::Vocab::PREMIS.hasMessageDigest
    end
  end

end
