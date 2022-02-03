INGEST_REPORTS_LOCATION = Rails.root.join('tmp/ingest_reports')
INDEX_OFFSET = 1

namespace :jupiter do
  desc 'batch ingest for multiple items from a csv file - used by ERA Admin and ERA Assistants'
  task :batch_ingest_items, [:csv_path] => :environment do |_t, args|
    csv_path = args[:csv_path]
    batch_ingest_csv(csv_path)
  end

  desc 'batch ingest for theses from a csv file - used to batch ingest theses from Thesis Deposit'
  task :batch_ingest_theses, [:csv_path] => :environment do |_t, args|
    csv_path = args.csv_path
    full_csv_path = File.expand_path(csv_path)
    csv_directory = File.dirname(full_csv_path)

    batch_ingest_csv(csv_path) do |object_data, index|
      thesis_ingest(object_data, index, csv_directory)
    end
  end

  desc 'batch ingest for legacy theses from a csv file'
  task :batch_ingest_legacy_theses, [:csv_path] => :environment do |_t, args|
    csv_path = args.csv_path
    full_csv_path = File.expand_path(csv_path)
    csv_directory = File.dirname(full_csv_path)

    batch_ingest_csv(csv_path) do |object_data, index|
      legacy_thesis_ingest(object_data, index, csv_directory)
    end
  end
end

def batch_ingest_csv(csv_path)
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
    ingest_errors = []
    ingested_data = []
    CSV.foreach(full_csv_path,
                headers: true,
                header_converters: :symbol,
                converters: :all).with_index(INDEX_OFFSET) do |object_data, index|
      object, e = if block_given?
                    yield(object_data, index)
                  else
                    item_ingest(object_data, index, csv_directory)
                  end
      if object.is_a?(Item) || object.is_a?(Thesis)
        successful_ingested << object
        ingested_data << object_data
      else
        object[:error_message] = e.message
        object[:backtrace] = e.backtrace.take(10).join("\n")
        ingest_errors << object
      end
    end
    generate_ingest_report(successful_ingested)
    headers = CSV.read(full_csv_path, headers: true).headers
    generate_ingest_production(ingested_data, headers)
    headers << 'error_message'
    headers << 'backtrace'
    generate_ingest_errors(ingest_errors, headers)
    log 'FINISH: Batch ingest completed!'
  else
    log "ERROR: Could not open file at '#{full_csv_path}'. Does the csv file exist at this location?"
    exit 1
  end
end

def log(message)
  puts "[#{Time.current.strftime('%F %T')}] #{message}"
end

def generate_ingest_report(successful_ingested_items)
  log 'REPORT: Generating ingest success report...'

  FileUtils.mkdir_p INGEST_REPORTS_LOCATION

  file_name = Time.current.strftime('%Y_%m_%d_%H_%M_%S')
  full_file_name = "#{INGEST_REPORTS_LOCATION}/#{file_name}_ingest_successes.csv"

  CSV.open(full_file_name, 'wb', headers: true) do |csv|
    csv << ['id', 'url', 'title'] # Add headers

    successful_ingested_items.each do |item|
      csv << [item.id,
              Rails.application.routes.url_helpers.item_url(item).gsub('era-test', ENV['HOSTNAME'].split('.')[0]), item.title]
    end
  end
  log 'REPORT: Ingest success report generated!'
  log "REPORT: You can view report here: #{full_file_name}"
end

def generate_ingest_errors(ingest_errors, headers)
  log 'REPORT: Generating ingest error report...'
  file_name = Time.current.strftime('%Y_%m_%d_%H_%M_%S')
  full_file_name = "#{INGEST_REPORTS_LOCATION}/#{file_name}_ingest_errors.csv"
  CSV.open(full_file_name, 'wb', headers: true) do |csv|
    csv << headers
    ingest_errors.each do |item|
      csv << item
    end
  end
  log 'REPORT: Ingest error report generated!'
  log "REPORT: You can view report here: #{full_file_name}"
end

def generate_ingest_production(ingested_data, headers)
  log 'REPORT: Generating ingest production report...'
  file_name = Time.current.strftime('%Y_%m_%d_%H_%M_%S')
  full_file_name = "#{INGEST_REPORTS_LOCATION}/#{file_name}_ingest_production.csv"
  CSV.open(full_file_name, 'wb', headers: true) do |csv|
    csv << headers
    ingested_data.each do |data|
      csv << data
    end
  end
  log 'REPORT: Ingest production report generated!'
  log "REPORT: You can view report here: #{full_file_name}"
end

def item_ingest(item_data, index, csv_directory)
  log "ITEM #{index}: Starting ingest of an item..."
  item = Item.new
  item.tap do |unlocked_obj|
    unlocked_obj.owner_id = 1
    unlocked_obj.title = item_data[:title]
    unlocked_obj.alternative_title = item_data[:alternate_title]

    if item_data[:item_type].present?
      unlocked_obj.item_type = ControlledVocabulary.era.item_type.from_value(item_data[:item_type])
    end

    # If item type is an article, we need to add an array of statuses to the publication status field...
    if item_data[:item_type] == 'article' && ['draft', 'published'].include?(item_data[:publication_status])
      unlocked_obj.publication_status = if item_data[:publication_status] == 'draft'
                                          [
                                            ControlledVocabulary.era.publication_status.draft,
                                            ControlledVocabulary.era.publication_status.submitted
                                          ]
                                        else
                                          [
                                            ControlledVocabulary.era.publication_status.published
                                          ]
                                        end
    end

    if item_data[:languages].present?
      unlocked_obj.languages = item_data[:languages].downcase.split('|').map do |language|
        ControlledVocabulary.era.language.from_value(language) if language.present?
      end
    end

    unlocked_obj.creators = item_data[:creators].split('|') if item_data[:creators].present?
    unlocked_obj.subject = item_data[:subject].split('|') if item_data[:subject].present?
    unlocked_obj.created = item_data[:created].to_s
    unlocked_obj.description = item_data[:description]

    # Handle visibility and embargo logic
    if item_data[:visibility].present?
      unlocked_obj.visibility = ControlledVocabulary.jupiter_core.visibility.from_value(item_data[:visibility].downcase)
    end

    if item_data[:visibility_after_embargo].present?
      unlocked_obj.visibility_after_embargo =
        ControlledVocabulary.jupiter_core.visibility.from_value(item_data[:visibility_after_embargo].downcase)
    end

    unlocked_obj.embargo_end_date = item_data[:embargo_end_date].to_date if item_data[:embargo_end_date].present?

    # Handle license vs rights
    if item_data[:license].present?
      unlocked_obj.license =
        ControlledVocabulary.era.license.from_value(item_data[:license]) ||
        ControlledVocabulary.era.old_license.from_value(item_data[:license])
    end
    unlocked_obj.rights = item_data[:rights]

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

  # Suport multiple file_name with '|' seperated
  item_data[:file_name].tr('\\', '/').split('|').each do |file_name|
    log "ITEM #{index}: Uploading file: #{file_name}..."
    File.open("#{csv_directory}/#{file_name}", 'r') do |file|
      item.add_and_ingest_files([file])
    end
  end

  log "ITEM #{index}: Setting thumbnail for item..."
  item.set_thumbnail(item.files.first) if item.files.first.present?

  log "ITEM #{index}: Successfully ingested an item! Item ID: '#{item.id}', #{item.title}"
  item
rescue StandardError => e
  log "ERROR: Ingest of item by #{item_data[:title]} failed! The following error occurred:"
  log "EXCEPTION: #{e.message}"
  log "BACKTRACE: #{e.backtrace.take(1).join("\n")}"
  [item_data, e]
end

def thesis_ingest(thesis_data, index, csv_directory)
  log "THESIS #{index}: Starting ingest of a thesis..."
  thesis = Thesis.new
  thesis.tap do |unlocked_obj|
    unlocked_obj.owner_id = 1
    unlocked_obj.title = thesis_data[:title]
    unlocked_obj.alternative_title = thesis_data[:other_titles]

    if thesis_data[:language].present?
      unlocked_obj.language =
        ControlledVocabulary.era.language.from_value(thesis_data[:language])
    end

    unlocked_obj.dissertant = thesis_data[:author] if thesis_data[:author].present?

    # Assumes the data received always have the graduation date follow the pattern of
    # "Fall yyyy" or "Spring yyyy"

    if thesis_data[:graduation_date].present?
      graduation_year_array = thesis_data[:graduation_date]&.match(/\d\d\d\d/)
      graduation_year = graduation_year_array[0]
      graduation_term_array = thesis_data[:graduation_date]&.match(/Fall|Spring/)
      graduation_term_string = graduation_term_array[0]
      graduation_term = '11' if graduation_term_string == 'Fall'
      graduation_term = '06' if graduation_term_string == 'Spring'
      unlocked_obj.graduation_date = "#{graduation_year}-#{graduation_term}"
    end
    unlocked_obj.abstract = thesis_data[:abstract]

    # Handle visibility and embargo logic
    unlocked_obj.visibility = unlocked_obj.visibility = ControlledVocabulary.jupiter_core.visibility.from_value(:embargo)

    if thesis_data[:date_of_embargo].present?
      unlocked_obj.visibility_after_embargo =
        ControlledVocabulary.jupiter_core.visibility.from_value(:public)
    end

    if thesis_data[:date_of_embargo].present?
      unlocked_obj.embargo_end_date = Date.strptime(thesis_data[:date_of_embargo], '%m/%d/%Y')
    end

    # Handle rights
    unlocked_obj.rights = thesis_data[:license]

    # Additional fields
    # Assumes the data received for approved_date and submitted_date follow the pattern of "D/M/Y".
    if thesis_data[:approved_date].present?
      approved_date_array = thesis_data[:approved_date].to_s.split('/').map(&:to_i)
      unlocked_obj.date_accepted = Date.new(approved_date_array[2], approved_date_array[0], approved_date_array[1])
    end

    if thesis_data[:submitted_date].present?
      submitted_date_array = thesis_data[:submitted_date].to_s.split('/').map(&:to_i)
      unlocked_obj.date_submitted = Date.new(submitted_date_array[2], submitted_date_array[0],
                                             submitted_date_array[1])
    end

    unlocked_obj.degree = thesis_data[:degree] if thesis_data[:degree].present?
    unlocked_obj.thesis_level = thesis_data[:degree_level] if thesis_data[:degree_level].present?
    unlocked_obj.institution = ControlledVocabulary.era.institution.from_value(:uofa)
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

  log "THESIS #{index}: Starting ingest of file for thesis..."

  # We only support for single file ingest, but this could easily be refactored for multiple files
  File.open("#{csv_directory}/#{thesis_data[:file_name]}", 'r') do |file|
    thesis.add_and_ingest_files([file])
  end
  log "THESIS #{index}: Setting thumbnail for thesis..."
  thesis.set_thumbnail(thesis.files.first) if thesis.files.first.present?
  log "THESIS #{index}: Successfully ingested an thesis! Thesis ID: '#{thesis.id}', #{thesis.title}"
  thesis
rescue StandardError => e
  log "ERROR: Ingest of thesis #{thesis_data[:title]} failed! The following error occurred:"
  log "EXCEPTION: #{e.message}"
  log "BACKTRACE: #{e.backtrace.take(1).join("\n")}"
  [thesis_data, e]
end

def legacy_thesis_ingest(thesis_data, index, csv_directory)
  log "THESIS #{index}: Starting ingest of a legacy thesis..."
  thesis = Thesis.new
  thesis.tap do |unlocked_obj|
    # constant fields
    unlocked_obj.owner_id = 1
    unlocked_obj.depositor = 'erahelp@ualberta.ca'
    unlocked_obj.institution = ControlledVocabulary.era.institution.from_value(:uofa)

    # legacy thesis template fields
    unlocked_obj.proquest = thesis_data[:proquest] if thesis_data[:proquest].present?
    unlocked_obj.dissertant = thesis_data[:dissertant]
    unlocked_obj.title = thesis_data[:title]
    unlocked_obj.alternative_title = thesis_data[:alternative_title] if thesis_data[:alternative_title].present?
    if thesis_data[:language].present?
      unlocked_obj.language =
        ControlledVocabulary.era.language.from_value(thesis_data[:language].downcase)
    end
    unlocked_obj.subject = thesis_data[:subject].split('|')
    unlocked_obj.abstract = thesis_data[:abstract] if thesis_data[:abstract].present?
    unlocked_obj.thesis_level = thesis_data[:thesis_level]
    unlocked_obj.degree = thesis_data[:degree]
    unlocked_obj.departments = thesis_data[:departments].split('|')
    unlocked_obj.specialization = thesis_data[:specialization] if thesis_data[:specialization].present?

    # Assumes the data received always have the graduation date follow the pattern of
    # "Fall yyyy" -> yyyy-11 or "Spring yyyy" -> yyyy-06 also accept "yyyy"
    if thesis_data[:graduation_date].is_a? Integer
      unlocked_obj.graduation_date = thesis_data[:graduation_date].to_s
    else
      graduation_year_array = thesis_data[:graduation_date]&.match(/\d\d\d\d/)
      graduation_year = graduation_year_array[0]
      graduation_term_array = thesis_data[:graduation_date]&.match(/Fall|Spring/)
      graduation_term_string = graduation_term_array[0]
      graduation_term = '11' if graduation_term_string == 'Fall'
      graduation_term = '06' if graduation_term_string == 'Spring'
      unlocked_obj.graduation_date = "#{graduation_year}-#{graduation_term}"
    end
    unlocked_obj.supervisors = thesis_data[:supervisors].split('|') if thesis_data[:supervisors].present?
    if thesis_data[:committee_members].present?
      unlocked_obj.committee_members = thesis_data[:committee_members].split('|')
    end
    unlocked_obj.rights = thesis_data[:rights]
    if thesis_data[:date_submitted].present?
      unlocked_obj.date_submitted = Date.strptime(thesis_data[:date_submitted].to_s,
                                                  '%Y-%m-%d')
    end
    if thesis_data[:date_accepted].present?
      unlocked_obj.date_accepted = Date.strptime(thesis_data[:date_accepted].to_s,
                                                 '%Y-%m-%d')
    end
    if thesis_data[:embargo_end_date].present?
      unlocked_obj.embargo_end_date = Date.strptime(thesis_data[:embargo_end_date].to_s,
                                                    '%Y-%m-%d')
    end
    if thesis_data[:visibility_after_embargo].present?
      unlocked_obj.visibility_after_embargo = unlocked_obj.visibility = ControlledVocabulary.jupiter_core.visibility.from_value(thesis_data[:visibility_after_embargo])
    end
    unlocked_obj.visibility = unlocked_obj.visibility = ControlledVocabulary.jupiter_core.visibility.from_value(thesis_data[:visibility])
    unlocked_obj.add_to_path(thesis_community_id, thesis_collection_id)

    # Add extra field, fedora3_uuid for fedora3 thesis redirecting
    # Ex: uuid:4cc160fc-a141-410f-a64d-d0119ad0b9fb
    unlocked_obj.fedora3_uuid = thesis_data[:fedora3_uuid] if thesis_data[:fedora3_uuid].present?

    # save thesis object
    unlocked_obj.save!
  end

  log "THESIS #{index}: Starting ingest of file for legacy thesis..."

  # We only support for single file ingest, but this could easily be refactored for multiple files
  File.open("#{csv_directory}/#{thesis_data[:file_name]}", 'r') do |file|
    thesis.add_and_ingest_files([file])
  end
  log "THESIS #{index}: Setting thumbnail for legacy thesis..."
  thesis.set_thumbnail(thesis.files.first) if thesis.files.first.present?
  log "THESIS #{index}: Successfully ingested an legacy thesis! Thesis ID: '#{thesis.id}', #{thesis.title}"
  thesis
rescue StandardError => e
  log "ERROR: Ingest of legacy thesis #{thesis_data[:title]} failed! The following error occurred:"
  log "EXCEPTION: #{e.message}"
  log "BACKTRACE: #{e.backtrace.take(1).join("\n")}"
  [thesis_data, e]
end

def thesis_community_id
  Community.where(title: 'Graduate Studies and Research, Faculty of').first.id
end

def thesis_collection_id
  Collection.where(title: 'Theses and Dissertations').first.id
end
