class Digitization::BatchMetadataIngest < Digitization::BatchIngest

  def spreadsheet_has_required_data
    return unless csvfile.attached? && attachment_changes['csvfile']

    graph = RDF::Graph.new
    CSV.foreach(attachment_changes['csvfile'].attachable[:io].path, headers: true) do |row|
      # Check if required fields are filled out
      errors.add(:csvfile, "Entity not found for row #{$INPUT_LINE_NUMBER} of spreadsheet") if row['Entity'].blank?
      if row['Property'].blank?
        errors.add(:csvfile,
                   "Property not found for row #{$INPUT_LINE_NUMBER} of spreadsheet")
      end
      errors.add(:csvfile, "Value not found for row #{$INPUT_LINE_NUMBER} of spreadsheet") if row['Value'].blank?
      next if errors.present?

      subject = RDF::URI.new(row['Entity'], validate: true)
      predicate = RDF::URI.new(row['Property'], validate: true)
      object = begin
        RDF::URI.new(row['Value'], validate: true)
      rescue StandardError
        RDF::Literal.new(row['Value'])
      end
      graph << [subject, predicate, object]
    end

    query_for_local_identifiers = RDF::Query.new do
      pattern [:collection, RDF::URI.new('http://rdaregistry.info/Elements/u/P60249'), :item_identifier]
    end

    errors.add(:csvfile, 'Graph contains no local identifiers') if graph.query(query_for_local_identifiers).blank?
  end

end
