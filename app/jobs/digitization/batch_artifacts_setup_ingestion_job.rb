class Digitization::BatchArtifactsSetupIngestionJob < ApplicationJob

  PEEL_ID_REGEX = /P0*(\d+).(\d*)/.freeze

  queue_as :default

  rescue_from(StandardError) do |exception|
    batch_artifact_ingest = arguments.first
    batch_artifact_ingest.update(error_message: exception.message, status: :failed)
    raise exception
  end

  def perform(batch_artifact_ingest)
    batch_artifact_ingest.csvfile.open do |file|
      CSV.foreach(file.path, headers: true) do |row|
        peel_number = row['Code'].match PEEL_ID_REGEX
        peel_id = peel_number[1]
        part_number = peel_number[2]

        noid = row['Noid']

        Digitization::BatchArtifactIngestJob.perform_later(batch_artifact_ingest, peel_id, part_number, noid)
      end
    end
  end

end
