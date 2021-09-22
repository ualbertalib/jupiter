namespace :digitization do
  desc 'batch ingest for multiple items metadata from a csv file - used by Admin and Assistants'
  task :batch_ingest, [:user, :title, :metadata_csv] => :environment do |_t, args|
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

    if args.metadata_csv.blank?
      log 'ERROR: metadata triples CSV path must be present. Please specify a valid metadata_csv as an argument'
      exit 1
    end

    if File.exist?(args.metadata_csv)
      batch_ingest = user.digitization_ingests.new(title: args.title)
      batch_ingest.metadata_csv.attach(io: File.open(args.metadata_csv.to_s), filename: 'metadata_graph.csv')

      Digitization::BatchIngestionJob.perform_later(batch_ingest) if batch_ingest.save!

      log "FINISH: #{batch_ingest.title} [id: #{batch_ingest.id}] enqueued!"
    else
      unless File.exist?(args.metadata_csv)
        log "ERROR: Could not open file at `#{args.metadata_csv}`. Does the csv file exist at this location?"
      end
      exit 1
    end
  end

  def log(message)
    puts "[#{Time.current.strftime('%F %T')}] #{message}"
  end
end
