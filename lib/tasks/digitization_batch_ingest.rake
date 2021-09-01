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

    log 'FINISH: Batch ingest enqueued!'
  end

  def log(message)
    puts "[#{Time.current.strftime('%F %T')}] #{message}"
  end
end
