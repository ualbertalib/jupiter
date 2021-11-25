namespace :digitization do
  desc 'batch ingest for multiple items metadata from a csv file - used by Admin and Assistants'
  task :batch_ingest_metadata, [:user, :title, :csv_path] => :environment do |_t, args|
    log 'START: Digitization Batch ingest from triples started...'

    user = User.find_by(email: args.user)
    if user.blank?
      log 'ERROR: Valid user must be selected. Please specify a valid email address as an argument'
      exit 1
    end

    if args.title.blank?
      log 'ERROR: Title must be present. Please specify a title as an argument'
      exit 1
    end

    if args.csv_path.blank?
      log 'ERROR: CSV path must be present. Please specify a valid csv_path as an argument'
      exit 1
    end

    if File.exist?(args.csv_path)
      batch_ingest = user.digitization_metadata_ingests.new(title: args.title)
      batch_ingest.csvfile.attach(io: File.open(args.csv_path.to_s), filename: 'metadata_graph.csv')

      Digitization::BatchMetadataIngestionJob.perform_later(batch_ingest) if batch_ingest.save!
    else
      log "ERROR: Could not open file at `#{args.csv_path}`. Does the csv file exist at this location?"
      exit 1
    end

    log "FINISH: Batch metadata ingest #{batch_ingest.id} enqueued!"
  end

  desc 'batch ingest for multiple items artifacts'
  task :batch_ingest_artifacts, [:user, :csv_path, :archival_information_package_path] => :environment do |_t, args|
    log 'START: Digitization Batch ingest from swift spreadsheet...'

    user = User.find_by(email: args.user)
    if user.blank?
      log 'ERROR: Valid user must be selected. Please specify a valid email address as an argument'
      exit 1
    end

    if args.csv_path.blank?
      log 'ERROR: CSV path must be present. Please specify a valid csv_path as an argument'
      exit 1
    end

    if args.archival_information_package_path.blank?
      log 'ERROR: Archival Information Package (AIP) path must be present. Please specify a valid path as an argument'
      exit 1
    end

    if File.exist?(args.csv_path) && File.exist?(args.archival_information_package_path)
      batch_artifact_ingest = user.digitization_artifact_setup_ingests.new
      batch_artifact_ingest.csvfile.attach(io: File.open(args.csv_path.to_s),
                                           filename: 'batch_manifest.csv')
      batch_artifact_ingest.archival_information_package_path = args.archival_information_package_path

      Digitization::BatchArtifactsSetupIngestionJob.perform_later(batch_artifact_ingest) if batch_artifact_ingest.save
    else
      unless File.exist?(args.csv_path)
        log "ERROR: Could not open file at `#{args.csv_path}`. Does the csv file exist at this location?"
      end
      unless File.exist?(args.archival_information_package_path)
        log "ERROR: Could not locate directory at `#{args.archival_information_package_path}`.\
         Does the archival information package (aip) path exist at this location?"
      end
      exit 1
    end

    log 'FINISH: Batch artifact ingest #{batch_artifact_setup_ingest.id} enqueued!'
  end

  def log(message)
    puts "[#{Time.current.strftime('%F %T')}] #{message}"
  end
end
