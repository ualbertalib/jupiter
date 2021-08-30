class BatchIngestionJob < ApplicationJob

  class GoogleAPIError < StandardError; end

  queue_as :default

  rescue_from(StandardError) do |exception|
    batch_ingest = BatchIngest.find(arguments.first)
    batch_ingest.update(error_message: exception.message, status: :failed)
    raise exception
  end

  def perform(id)
    batch_ingest = BatchIngest.find(id)

    batch_ingest.processing!

    google_credentials = GoogleDriveClientService.new(
      access_token: batch_ingest.access_token,
      refresh_token: batch_ingest.refresh_token,
      expires_in: batch_ingest.expires_in,
      issued_at: batch_ingest.issued_at
    )

    raise GoogleAPIError if google_credentials.nil?

    spreadsheet = google_credentials.download_spreadsheet(batch_ingest.google_spreadsheet_id)

    ActiveRecord::Base.transaction do
      spreadsheet.each do |row|
        item_file = batch_ingest.batch_ingest_files.find { |file| file.google_file_name == row['file_name'] }

        next if item_file.blank?

        item = item_ingest(batch_ingest, row)
        file_ingest(item, item_file, google_credentials)
      end
    end

    batch_ingest.completed!
  end

  private

  def item_ingest(batch_ingest, item_data)
    item = batch_ingest.items.new
    item.tap do |unlocked_obj|
      unlocked_obj.owner_id = item_data['owner_id']
      unlocked_obj.title = item_data['title']
      unlocked_obj.alternative_title = item_data['alternate_title']

      if item_data['type'].present?
        unlocked_obj.item_type = ControlledVocabulary.era.item_type.send(item_data['type'].to_sym)
      end

      # If item type is an article, we need to add an array of statuses to the publication status field...
      if item_data['type'] == 'article' && ['draft', 'published'].include?(item_data['publication_status'])
        unlocked_obj.publication_status = if item_data['publication_status'] == 'draft'
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

      if item_data['languages'].present?
        unlocked_obj.languages = item_data['languages'].split('|').map(&:strip).map do |language|
          ControlledVocabulary.era.language.send(language.to_sym) if language.present?
        end
      end

      unlocked_obj.creators = item_data['creators'].split('|').map(&:strip) if item_data['creators'].present?
      unlocked_obj.subject = item_data['subjects'].split('|').map(&:strip) if item_data['subjects'].present?
      unlocked_obj.created = item_data['date_created'].to_s
      unlocked_obj.description = item_data['description']

      # Handle visibility and embargo logic
      if item_data['visibility'].present?
        unlocked_obj.visibility = ControlledVocabulary.jupiter_core.visibility.send(item_data['visibility'].to_sym)
      end

      if item_data['visibility_after_embargo'].present?
        unlocked_obj.visibility_after_embargo =
          ControlledVocabulary.jupiter_core.visibility.send(item_data['visibility_after_embargo'].to_sym)
      end

      unlocked_obj.embargo_end_date = item_data['embargo_end_date'].to_date if item_data['embargo_end_date'].present?

      # Handle license vs rights
      if item_data['license'].present?
        if item_data['license'] == 'license_text'
          unlocked_obj.rights = item_data['license_text']
        else
          unlocked_obj.license =
            ControlledVocabulary.era.license.send(item_data['license'].to_sym) ||
            ControlledVocabulary.era.old_license.send(item_data['license'].to_sym)
        end
      end

      # Additional fields
      if item_data['contributors'].present?
        unlocked_obj.contributors = item_data['contributors'].split('|').map(&:strip)
      end
      unlocked_obj.spatial_subjects = item_data['places'].split('|').map(&:strip) if item_data['places'].present?
      if item_data['time_periods'].present?
        unlocked_obj.temporal_subjects = item_data['time_periods'].split('|').map(&:strip)
      end
      unlocked_obj.is_version_of = item_data['citations'].split('|').map(&:strip) if item_data['citations'].present?
      unlocked_obj.source = item_data['source']
      unlocked_obj.related_link = item_data['related_item']

      # We only support single communities/collections pairs for time being,
      # could accomodate multiple pairs without much work here
      unlocked_obj.add_to_path(item_data['community_id'], item_data['collection_id'])

      unlocked_obj.save!
    end

    item
  end

  def file_ingest(item, item_file, google_credentials)
    file = google_credentials.download_file(item_file.google_file_id, item_file.google_file_name)
    item.add_and_ingest_files([file])
    item.set_thumbnail(item.files.first) if item.files.first.present?
  end

end