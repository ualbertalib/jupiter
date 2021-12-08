namespace :digitization do
  desc 'batch ingest for multiple items metadata from a csv file - used by Admin and Assistants'
  task batch_ingest_metadata: :environment do
    options = {}
    parser = OptionParser.new
    parser.accept(User) do |user_email|
      User.find_by(email: user_email)
    end
    parser.accept(File) do |filename|
      File.open(filename)
    end
    parser.banner = 'Usage: rails digitization:batch_ingest_metadata -- [options]'

    parser.on('--user EMAIL', User) { |user| options[:user] = user }
    parser.on('--title TITLE', String) { |title| options[:title] = title }
    parser.on('--csv FILE', File) { |file| options[:csvfile] = file }

    arguments = parser.order!(ARGV)
    parser.parse!(arguments)

    log 'START: Digitization Batch ingest from triples started...'

    batch_ingest = options[:user].digitization_metadata_ingests.new(title: options[:title])
    batch_ingest.csvfile.attach(io: options[:csvfile], filename: 'metadata_graph.csv')

    Digitization::BatchMetadataIngestionJob.perform_later(batch_ingest) if batch_ingest.save!
    log 'FINISH: Batch ingest enqueued!'
  end

  def log(message)
    puts "[#{Time.current.strftime('%F %T')}] #{message}"
  end
end
