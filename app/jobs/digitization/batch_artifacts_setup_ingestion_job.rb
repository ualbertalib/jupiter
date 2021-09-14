class Digitization::BatchArtifactsSetupIngestionJob < ApplicationJob

  queue_as :default

  rescue_from(StandardError) do |exception|
    batch_ingest = arguments.first
    batch_ingest.update(error_message: exception.message, status: :failed)
    raise exception
  end

  def perform(batch_ingest)
    batch_ingest.csvfile.open do |file|
      CSV.foreach(file.path, headers: true) do |row|
        peel_number = row['Code'].match Digitization::PEEL_ID_REGEX
        peel_id = peel_number[1]
        part_number = peel_number[2]

        noid = row['Noid']

        Digitization::BatchArtifactIngestJob.perform_later(batch_ingest, peel_id, part_number, noid)
      end
    end
  end

end
