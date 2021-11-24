class Digitization::BatchArtifactIngestJob < ApplicationJob

  queue_as :default

  rescue_from(StandardError) do |exception|
    batch_artifact_ingest = arguments.first
    batch_artifact_ingest.update(error_message: exception.message)

    book = Digitization::Book.find_by(peel_id: arguments[1], part_number: arguments[2])
    book.failed! if book.present?

    raise exception
  end

  def perform(batch_artifact_ingest, peel_id, part_number, noid)
    book = Digitization::Book.find_by!(peel_id: peel_id, part_number: part_number)
    book.processing!

    add_link_to_preservation_storage(book, noid)

    add_pdf(batch_artifact_ingest, book, noid)

    add_fulltext(batch_artifact_ingest, book, noid)

    book.completed! if book.save!
  end

  private

  def add_link_to_preservation_storage(book, noid)
    book.preservation_storage = 'OpenStack/Swift'
    book.swift_container = 'peel'
    book.swift_noid = noid
  end

  def add_pdf(batch_artifact_ingest, book, noid)
    File.open("#{batch_artifact_ingest.archival_information_package_path}#{noid}/pdf/1.pdf",
              'r') do |high_res_pdf|
      book.add_and_ingest_files([high_res_pdf])
    end
    book.set_thumbnail(book.files.first) if book.files.first.present?
  end

  def add_fulltext(batch_artifact_ingest, book, noid)
    path_to_ocr_xml = "#{batch_artifact_ingest.archival_information_package_path}#{noid}/alto"
    fulltext = extract_alto_fulltext(path_to_ocr_xml)
    book.create_fulltext!(text: fulltext)
  end

  def extract_alto_fulltext(alto_dir)
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

end
