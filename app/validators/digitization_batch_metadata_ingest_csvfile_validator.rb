class DigitizationBatchMetadataIngestCsvfileValidator < ActiveModel::EachValidator

  # This Validator will validate if a given csv file id has all
  #  the required data needed to be successfully batch ingested
  def validate_each(record, attribute, _value)
    return unless record.csvfile.attached? && record.attachment_changes['csvfile']

    graph = RDF::Graph.new
    CSV.foreach(record.attachment_changes['csvfile'].attachable[:io].path, headers: true) do |row|
      # Check if required fields are filled out
      if row['Entity'].blank?
        record.errors.add(attribute, "Entity not found for row #{$INPUT_LINE_NUMBER} of spreadsheet")
      end
      if row['Property'].blank?
        record.errors.add(attribute, "Property not found for row #{$INPUT_LINE_NUMBER} of spreadsheet")
      end
      if row['Value'].blank?
        record.errors.add(attribute, "Value not found for row #{$INPUT_LINE_NUMBER} of spreadsheet")
      end
      next if record.errors.present?

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

    return if graph.query(query_for_local_identifiers).present?

    record.errors.add(attribute, 'Graph contains no local identifiers')
  end

end
