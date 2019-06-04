INGEST_REPORTS_LOCATION = Rails.root.join('tmp', 'ingest_reports')
INDEX_OFFSET = 1

namespace :jupiter do
  desc 'batch ingest for multiple items from a csv file - used by ERA Admin and ERA Assistants'
  task :batch_ingest_items, [:csv_path] => :environment do |_t, args|
    csv_path = args.csv_path
    batch_ingest_csv(csv_path)
  end

  desc 'batch ingest for theses from a csv file - used to batch ingest theses from Thesis Deposit'
  task :batch_ingest_theses, [:csv_path] => :environment do |_t, args|
    csv_path = args.csv_path
    batch_ingest_csv(csv_path, 'thesis')
  end
end

def batch_ingest_csv(csv_path, ingest_type = 'item')
  require 'csv'
  require 'fileutils'
  log 'START: Batch ingest started...'

  if csv_path.blank?
    log 'ERROR: CSV path must be present. Please specify a valid csv_path as an argument'
    exit 1
  end

  full_csv_path = File.expand_path(csv_path)
  csv_directory = File.dirname(full_csv_path)

  if File.exist?(full_csv_path)
    successful_ingested = []
    if ingest_type == 'thesis'
      checksums = generate_checksums(csv_directory)
      CSV.foreach(full_csv_path,
                  headers: true,
                  header_converters: :symbol,
                  converters: :all).with_index(INDEX_OFFSET) do |thesis_data, index|
        thesis = thesis_ingest(thesis_data, index, csv_directory, checksums)

        successful_ingested << thesis
      end
    else
      CSV.foreach(full_csv_path,
                  headers: true,
                  header_converters: :symbol,
                  converters: :all).with_index(INDEX_OFFSET) do |item_data, index|
        item = item_ingest(item_data, index, csv_directory)
        successful_ingested << item
      end
    end
    generate_ingest_report(successful_ingested)

    log 'FINISH: Batch ingest completed!'
  else
    log "ERROR: Could not open file at `#{full_csv_path}`. Does the csv file exist at this location?"
    exit 1
  end
end

def thesis_community_id
  thesis_comm_id = Community.where(title: 'Graduate Studies and Research, Faculty of').first.id
  thesis_comm_id
end

def thesis_collection_id
  thesis_coll_id = Collection.where(title: 'Theses and Dissertations').first.id
  thesis_coll_id
end

def log(message)
  puts "[#{Time.current.strftime('%F %T')}] #{message}"
end

def generate_ingest_report(successful_ingested)
  log 'REPORT: Generating ingest report...'

  FileUtils.mkdir_p INGEST_REPORTS_LOCATION

  file_name = Time.current.strftime('%Y_%m_%d_%H_%M_%S')
  full_file_name = "#{INGEST_REPORTS_LOCATION}/#{file_name}.csv"
  CSV.open(full_file_name, 'wb', headers: true) do |csv|
    csv << ['id', 'url', 'title'] # Add headers

    successful_ingested.each do |item|
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

    # Handle visibility and embargo logic
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
    unlocked_obj.is_version_of = item_data[:citations].split('|') if item_data[:citations].present?
    unlocked_obj.source = item_data[:source]
    unlocked_obj.related_link = item_data[:related_item]

    # We only support single communities/collections pairs for time being,
    # could accomodate multiple pairs without much work here
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
rescue StandardError => e
  log 'ERROR: Ingest of item failed! The following error occured:'
  log "EXCEPTION: #{e.message}"
  log 'WARNING: Please be careful with rerunning batch ingest! Duplication of items may happen '\
      'if previous items were successfully deposited.'
  exit 1
end

def thesis_ingest(thesis_data, index, csv_directory, checksums)
  log "THESIS #{index}: Starting ingest of a thesis..."
  thesis = Thesis.new_locked_ldp_object
  thesis.unlock_and_fetch_ldp_object do |unlocked_obj|
    unlocked_obj.owner = 1
    unlocked_obj.title = thesis_data[:title]
    unlocked_obj.alternative_title = thesis_data[:other_titles]

    if thesis_data[:language].present?
      unlocked_obj.language =
        CONTROLLED_VOCABULARIES[:language].send(thesis_data[:language].to_sym)
    end

    unlocked_obj.dissertant = thesis_data[:author] if thesis_data[:author].present?

    # Assumes the data received always have the graduation date follow the pattern of
    # "Fall yyyy" or "Spring yyyy"

    if thesis_data[:graduation_date].present?
      graduation_year_array = thesis_data[:graduation_date]&.match(/\d\d\d\d/)
      graduation_year = graduation_year_array.first
      graduation_term_array = thesis_data[:graduation_date]&.match(/Fall|Spring/)
      graduation_term_string = graduation_term_array.first
      graduation_term = '11' if graduation_term_string == 'Fall'
      graduation_term = '06' if graduation_term_string == 'Spring'
      unlocked_obj.graduation_date = graduation_year + '-' + graduation_term
    end
    unlocked_obj.abstract = thesis_data[:abstract]

    # Handle visibility and embargo logic
    unlocked_obj.visibility = CONTROLLED_VOCABULARIES[:visibility].send('embargo'.to_sym)

    if thesis_data[:date_of_embargo].present?
      unlocked_obj.visibility_after_embargo =
        CONTROLLED_VOCABULARIES[:visibility].send('public'.to_sym)
    end

    if thesis_data[:date_of_embargo].present?
      unlocked_obj.embargo_end_date = Date.strptime(thesis_data[:date_of_embargo], '%m/%d/%Y')
    end

    # Handle rights
    unlocked_obj.rights = thesis_data[:license]

    # Additional fields
    unlocked_obj.date_accepted = thesis_data[:approved_date].to_date if thesis_data[:approved_date].present?
    unlocked_obj.date_submitted = thesis_data[:submitted_date].to_date if thesis_data[:submitted_date].present?

    unlocked_obj.degree = thesis_data[:degree] if thesis_data[:degree].present?
    unlocked_obj.thesis_level = thesis_data[:degree_level] if thesis_data[:degree_level].present?
    unlocked_obj.institution = CONTROLLED_VOCABULARIES[:institution].send('uofa'.to_sym)
    unlocked_obj.specialization = thesis_data[:specialization] if thesis_data[:specialization].present?

    unlocked_obj.subject = thesis_data[:keywords].split('|') if thesis_data[:keywords].present?
    unlocked_obj.supervisors = thesis_data[:supervisor_info].split('|') if thesis_data[:supervisor_info].present?
    unlocked_obj.departments = if thesis_data[:conjoint_departments].present?
                                 [thesis_data[:department]] + thesis_data[:conjoint_departments].split('|')
                               else
                                 [thesis_data[:department]]
                               end
    unlocked_obj.is_version_of = thesis_data[:citation] if thesis_data[:citation].present?
    unlocked_obj.depositor = thesis_data[:email] if thesis_data[:email]

    # We only support single communities/collections pairs for time being,
    # could accomodate multiple pairs without much work here
    unlocked_obj.add_to_path(thesis_community_id, thesis_collection_id)

    unlocked_obj.save!
  end

  log "THESIS #{index}: Identifying file by checksum ..."

  file_name = checksums[thesis_data[:md5sum]]
  puts file_name

  log "THESIS #{index}: Starting ingest of file for thesis..."

  # We only support for single file ingest, but this could easily be refactored for multiple files
  File.open("#{csv_directory}/#{file_name}", 'r') do |file|
    thesis.add_and_ingest_files([file])
  end

  log "THESIS #{index}: Setting thumbnail for thesis..."

  thesis.set_thumbnail(thesis.files.first) if thesis.files.first.present?

  log "THESIS #{index}: Successfully ingested an thesis! Thesis ID: `#{thesis.id}`"

  thesis
rescue StandardError => ex
  log "ERROR: Ingest of thesis by #{thesis_data[:author]} failed! The following error occured:"
  log "EXCEPTION: #{ex.message}"
  log 'WARNING: Please be careful with rerunning batch ingest! Duplication of theses may happen '\
      'if previous theses were successfully deposited.'
  exit
end

def generate_checksums(csv_directory)
  require 'digest/md5'
  checksums = {}
  Dir.glob(csv_directory + '/*.pdf').each do |f|
    checksum = Digest::MD5.hexdigest(File.read(f))
    checksums[checksum] = File.basename(f)
  end
  checksums
end
