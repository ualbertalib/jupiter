namespace :digitization do
  desc 'batch ingest for multiple items metadata from a csv file - used by Admin and Assistants'
  task :batch_ingest_metadata, [:user, :csv_path] => :environment do |_t, args|
    log 'START: Digitization Batch ingest from triples started...'

    user = User.find_by(email: args.user)
    batch_ingest = user.digitization_metadata_ingests.new
    batch_ingest.csvfile.attach(io: File.open(args.csv_path.to_s), filename: 'metadata_graph.csv')

    Digitization::BatchMetadataIngestionJob.perform_later(batch_ingest) if batch_ingest.save!

    log 'FINISH: Batch ingest completed!'
  end

  def log(message)
    puts "[#{Time.current.strftime('%F %T')}] #{message}"
  end
end
