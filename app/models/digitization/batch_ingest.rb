class Digitization::BatchIngest < ApplicationRecord

  enum status: { created: 0, processing: 1, completed: 2, failed: 3 }

  belongs_to :user

  has_many :books, dependent: :nullify, class_name: 'Digitization::Book',
                   foreign_key: :digitization_batch_metadata_ingest_id,
                   inverse_of: :digitization_batch_metadata_ingest
  has_one_attached :metadata_csv
  has_one_attached :manifest_csv

  validates :metadata_csv, presence: true
  validates :manifest_csv, presence: true
  validates :title, presence: true
  validate :metadata_csv_has_required_data
  validate :manifest_csv_has_required_data

  # TODO move to validation class
  def metadata_csv_has_required_data
    return unless metadata_csv.attached? && attachment_changes['metadata_csv']

    graph = RDF::Graph.new
    CSV.foreach(attachment_changes['metadata_csv'].attachable[:io].path, headers: true) do |row|
      # Check if required fields are filled out
      errors.add(:metadata_csv, "Entity not found for row #{$INPUT_LINE_NUMBER} of spreadsheet") if row['Entity'].blank?
      if row['Property'].blank?
        errors.add(:metadata_csv,
                   "Property not found for row #{$INPUT_LINE_NUMBER} of spreadsheet")
      end
      errors.add(:metadata_csv, "Value not found for row #{$INPUT_LINE_NUMBER} of spreadsheet") if row['Value'].blank?
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

    errors.add(:metadata_csv, 'Graph contains no local identifiers') if graph.query(query_for_local_identifiers).blank?
  end

  def manifest_csv_has_required_data
    return unless manifest_csv.attached? && attachment_changes['manifest_csv']

    CSV.foreach(attachment_changes['manifest_csv'].attachable[:io].path, headers: true) do |row|
      # Check if required fields are filled out
      if row['Code'].blank?
        errors.add(:manifest_csv,
                   "Local Identifier (Code) not found for row #{$INPUT_LINE_NUMBER} of spreadsheet")
      end
      errors.add(:manifest_csv, "Noid not found for row #{$INPUT_LINE_NUMBER} of spreadsheet") if row['Noid'].blank?
    end
  end

  # TODO: compare content in sheets to see if the identifiers are consistent

  def fulltext(noid)
    alto_dir = "#{archival_information_package_path}#{noid}/alto"
    fulltext = []

    Minitar.unpack("#{alto_dir}/1.tar", alto_dir)

    Dir.glob("#{alto_dir}/**/*.xml").each do |alto_file|
      doc = File.open(alto_file) { |f| Nokogiri::XML(f) }

      # Search for nodes by xpath
      doc.xpath('//TextLine').each do |line|
        line_of_text = ''
        line.xpath('String/@CONTENT').each do |word|
          line_of_text << "#{word.content} "
        end
        fulltext << line_of_text
      end
    end

    FileUtils.rm_r "#{alto_dir}/ALTO/" if Dir.exist?("#{alto_dir}/ALTO/")

    fulltext.join('\n')
  end

  def pdf_path(noid)
    "#{archival_information_package_path}#{noid}/pdf/1.pdf"
  end

end
