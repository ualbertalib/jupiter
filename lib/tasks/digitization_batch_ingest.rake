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

  desc 'report on batch_ingest progress - used by Admin and Assistants'
  task :batch_ingest_report, [:id, :limit] => :environment do |_t, args|
    limit = args.limit.presence || 10
    if args.id.blank?
      # Use `Kernel#format` to ensure that the columns line up with enough space for the expected values.
      # - The `id`s will be exactly 38 characters.
      # - Give `title` 80 characters of space.
      # - `processing` should be the longest `status`
      # - batch `size` should be pretty small to ensure that the jobs can finish in a timely manner
      # rubocop:disable Style/RedundantFormat
      puts format '%38s,%80s,%12s,%7s', 'id', 'title', 'status', 'size'
      # rubocop:enable Style/RedundantFormat
      Digitization::BatchMetadataIngest.order(created_at: :desc).limit(limit).each do |batch_ingest|
        puts format '%38s,%80s,%12s,%7d', batch_ingest.id, batch_ingest.title, batch_ingest.status,
                    batch_ingest.books.count
      end
    else
      batch_ingest = Digitization::BatchMetadataIngest.find(args.id)
      puts "#{batch_ingest.title} [#{batch_ingest.id}]"
      puts batch_ingest.status
      puts batch_ingest.error_message if batch_ingest.failed?
      batch_ingest.books.each do |book|
        puts "#{book.id},\t#{book.peel_number},\t" \
             "#{Rails.application.routes.url_helpers.digitization_book_url(book)},\t#{book.title}"
      end
    end
  end

  def log(message)
    puts "[#{Time.current.strftime('%F %T')}] #{message}"
  end
end
