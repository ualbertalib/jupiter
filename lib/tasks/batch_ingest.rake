
namespace :jupiter do
  desc 'batch ingest for multiple items from a csv file - used by ERA Admin and ERA Assistants'
  task :batch_ingest_items, [:csv_path] => :environment do |_t, args|
    require 'csv'

    log 'START: Batch ingest started...'

    csv_path = args.csv_path

    if csv_path.blank?
      log 'ERROR: CSV path must be present. Please specify a valid csv_path as an argument when running the rake task'
      exit 1
    end

    # convert any relative paths to absolute paths
    full_csv_path = File.expand_path(csv_path)
    csv_directory = File.dirname(full_csv_path)

    if File.exist?(full_csv_path)

      successful_items_list = []

      CSV.foreach(full_csv_path, :headers => true, :header_converters => :symbol, :converters => :all) do |row|
        log 'Starting ingest of an item...'

        item = ingest(row, csv_directory)

        successful_items_list << item

        log "Successfully ingested a item! Item ID `#{item.id}`"
      end

      # spit items into report file
      generate_ingest_report(successful_items_list)


      log 'FINISH: Batch ingest completed!'
    else
      log "ERROR: Could not open file at `#{full_csv_path}`. Does this file exist?"
      exit 1
    end
  end
end


def log(message)
  puts "[#{DateTime.now.strftime('%F %T')}] #{message}"
end


INGEST_REPORTS_LOCATION = Rails.root + "tmp/ingest_reports/"

def generate_ingest_report(successful_items_list)
  log 'Generating ingest report...'

  FileUtils.mkdir_p INGEST_REPORTS_LOCATION

  file_name = Time.now.strftime('%Y_%m_%d_%H_%M_%S')
  full_file_name = "#{INGEST_REPORTS_LOCATION}/#{file_name}.csv"

  CSV.open(full_file_name, 'wb', headers: true) do |csv|
    csv << ['id', 'url', 'title']
    successful_items_list.each do |item|
      csv << [item.id, Rails.application.routes.url_helpers.item_url(item), item.title]
    end
  end


  log "Ingest report successfully generated! You can view report here: #{full_file_name}"
end

def ingest(row, csv_directory)
  begin
    item = Item.new_locked_ldp_object
    item.unlock_and_fetch_ldp_object do |unlocked_obj|
      unlocked_obj.owner = row[:owner_id]
      unlocked_obj.title = row[:title]
      unlocked_obj.alternative_title = row[:alternate_title]

      unlocked_obj.item_type = CONTROLLED_VOCABULARIES[:item_type].send(row[:type].to_sym) if row[:type].present?

      # ...bad model design, need to map publication_status to an array of statuses...

      if row[:type] == 'article' && ['draft', 'published'].include?(row[:publication_status])
        if row[:publication_status] == 'draft'
          unlocked_obj.publication_status = [
              CONTROLLED_VOCABULARIES[:publication_status].draft,
              CONTROLLED_VOCABULARIES[:publication_status].submitted
            ]
        else
          unlocked_obj.publication_status = [
            CONTROLLED_VOCABULARIES[:publication_status].published
          ]
        end
      end


      unlocked_obj.languages = row[:languages].split("|").map { |language| CONTROLLED_VOCABULARIES[:language].send(language.to_sym) if language.present? } if row[:languages].present?
      unlocked_obj.creators = row[:creators].split("|") if row[:creators].present?
      unlocked_obj.subject = row[:subjects].split("|") if row[:subjects].present?
      unlocked_obj.created = row[:date_created].to_s
      unlocked_obj.description = row[:description]

      # Handle visibility plus embargo logic
      unlocked_obj.visibility = CONTROLLED_VOCABULARIES[:visibility].send(row[:visibility].to_sym) if row[:visibility].present?
      unlocked_obj.visibility_after_embargo = CONTROLLED_VOCABULARIES[:visibility].send(row[:visibility_after_embargo].to_sym) if row[:visibility_after_embargo].present?
      unlocked_obj.embargo_end_date = row[:embargo_end_date].to_date if row[:embargo_end_date].present?

      # Handle license vs rights
      unlocked_obj.license = CONTROLLED_VOCABULARIES[:license].send(row[:license].to_sym) if row[:license].present?
      unlocked_obj.rights = row[:license_text]

      # Additional fields
      unlocked_obj.contributors = row[:contributors].split("|") if row[:contributors].present?
      unlocked_obj.spatial_subjects = row[:places].split("|") if row[:places].present?
      unlocked_obj.temporal_subjects = row[:time_periods].split("|") if row[:time_periods].present?
      # citations of previous publication apparently maps to is_version_of
      unlocked_obj.is_version_of = row[:citations].split("|") if row[:citations].present?
      unlocked_obj.source = row[:source]
      unlocked_obj.related_link = row[:related_item]

      # unlocked_obj.member_of_paths = []

      # TODO: Support mutliple communities/collections?
      # draft_item.each_community_collection do |community, collection|
        unlocked_obj.add_to_path(row[:community_id], row[:collection_id])
      # end

      unlocked_obj.save!

    end

    # check file exist?  if File.exist?(file_location)
    # No support for multiple files, but this could easily be added here
    File.open("#{csv_directory}/#{row[:file_name]}", 'r') do |file|
      item.add_and_ingest_files([file])
    end

    item.set_thumbnail(item.files.first) if item.files.first.present?

    item
  rescue => e
    log "ERROR: Failed to ingest item with error: #{e.message}"
    exit 1
  end
end
