INGEST_REPORTS_LOCATION = Rails.root.join('tmp', 'ingest_reports')
CSV_INDEX_OFFSET = 1

namespace :jupiter do
  desc 'batch ingest for multiple items from a csv file - used by ERA Admin and ERA Assistants'
  task :batch_ingest_items, [:csv_path] => :environment do |_t, args|
    require 'csv'

    log 'START: Batch ingest started...'
    csv_path = args.csv_path

    if csv_path.blank?
      log 'ERROR: CSV path must be present. Please specify a valid csv_path as an argument'
      exit 1
    end

    full_csv_path = File.expand_path(csv_path)
    csv_directory = File.dirname(full_csv_path)

    if File.exist?(full_csv_path)
      successful_ingested_items = []

      CSV.foreach(full_csv_path,
                  headers: true,
                  header_converters: :symbol,
                  converters: :all).with_index(CSV_INDEX_OFFSET) do |item_data, index|
        item = item_ingest(item_data, index, csv_directory)
        successful_ingested_items << item
      end

      # spit items into report file
      generate_ingest_report(successful_ingested_items)

      log 'FINISH: Batch ingest completed!'
    else
      log "ERROR: Could not open file at `#{full_csv_path}`. Does the csv file exist at this location?"
      exit 1
    end
  end
end

def log(message)
  puts "[#{Time.current.strftime('%F %T')}] #{message}"
end

def generate_ingest_report(successful_ingested_items)
  log 'REPORT: Generating ingest report...'

  FileUtils.mkdir_p INGEST_REPORTS_LOCATION

  file_name = Time.current.strftime('%Y_%m_%d_%H_%M_%S')
  full_file_name = "#{INGEST_REPORTS_LOCATION}/#{file_name}.csv"

  CSV.open(full_file_name, 'wb', headers: true) do |csv|
    csv << ['id', 'url', 'title']
    successful_ingested_items.each do |item|
      csv << [item.id, Rails.application.routes.url_helpers.item_url(item), item.title]
    end
  end

  log 'REPORT: Ingest report successfully generated!'
  log "REPORT: You can view report here: #{full_file_name}"
end

def item_ingest(item_data, index, csv_directory)
  log "ITEM #{index}: Starting ingest of an item..."

  item = Item.new_locked_ldp_object
  item.unlock_and_fetch_ldp_object do |unlocked_obj|
    unlocked_obj.owner = item_data[:owner_id]
    unlocked_obj.title = item_data[:title]
    unlocked_obj.alternative_title = item_data[:alternate_title]

    if item_data[:type].present?
      unlocked_obj.item_type = CONTROLLED_VOCABULARIES[:item_type].send(item_data[:type].to_sym)
    end

    # If item type is an article, we need to add an array of statuses to the publication status field...
    if item_data[:type] == 'article' && ['draft', 'published'].include?(item_data[:publication_status])
      unlocked_obj.publication_status = if item_data[:publication_status] == 'draft'
                                          [
                                            CONTROLLED_VOCABULARIES[:publication_status].draft,
                                            CONTROLLED_VOCABULARIES[:publication_status].submitted
                                          ]
                                        else
                                          [
                                            CONTROLLED_VOCABULARIES[:publication_status].published
                                          ]
                                        end
    end

    if item_data[:languages].present?
      unlocked_obj.languages = item_data[:languages].split('|').map do |language|
        CONTROLLED_VOCABULARIES[:language].send(language.to_sym) if language.present?
      end
    end

    unlocked_obj.creators = item_data[:creators].split('|') if item_data[:creators].present?
    unlocked_obj.subject = item_data[:subjects].split('|') if item_data[:subjects].present?
    unlocked_obj.created = item_data[:date_created].to_s
    unlocked_obj.description = item_data[:description]

    # Handle visibility plus embargo logic
    if item_data[:visibility].present?
      unlocked_obj.visibility = CONTROLLED_VOCABULARIES[:visibility].send(item_data[:visibility].to_sym)
    end

    if item_data[:visibility_after_embargo].present?
      unlocked_obj.visibility_after_embargo =
        CONTROLLED_VOCABULARIES[:visibility].send(item_data[:visibility_after_embargo].to_sym)
    end

    unlocked_obj.embargo_end_date = item_data[:embargo_end_date].to_date if item_data[:embargo_end_date].present?

    # Handle license vs rights
    if item_data[:license].present?
      unlocked_obj.license = CONTROLLED_VOCABULARIES[:license].send(item_data[:license].to_sym)
    end
    unlocked_obj.rights = item_data[:license_text]

    # Additional fields
    unlocked_obj.contributors = item_data[:contributors].split('|') if item_data[:contributors].present?
    unlocked_obj.spatial_subjects = item_data[:places].split('|') if item_data[:places].present?
    unlocked_obj.temporal_subjects = item_data[:time_periods].split('|') if item_data[:time_periods].present?
    # citations of previous publication apparently maps to is_version_of
    unlocked_obj.is_version_of = item_data[:citations].split('|') if item_data[:citations].present?
    unlocked_obj.source = item_data[:source]
    unlocked_obj.related_link = item_data[:related_item]

    # We only support single communities/collections pairs for time being,
    # could accomodate multiple without much work here
    unlocked_obj.add_to_path(item_data[:community_id], item_data[:collection_id])

    unlocked_obj.save!
  end

  log "ITEM #{index}: Starting ingest of file for item..."

  # We only support for single file ingest, but this could easily be refactored for multiple files
  File.open("#{csv_directory}/#{item_data[:file_name]}", 'r') do |file|
    item.add_and_ingest_files([file])
  end

  log "ITEM #{index}: Setting thumbnail for item..."
  item.set_thumbnail(item.files.first) if item.files.first.present?

  log "ITEM #{index}: Successfully ingested an item! Item ID: `#{item.id}`"

  item
rescue StandardError => ex
  log 'ERROR: Ingest of item failed! The following error occured:'
  log "EXCEPTION: #{ex.message}"
  log 'WARNING: Please be careful with rerunning batch ingest! Duplication of items may happen '\
      'if previous items were successfully deposited.'
  exit 1
end
