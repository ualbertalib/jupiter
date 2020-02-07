module Admin::ItemHistoryHelper
  def get_history(versions)
    history = []
    versions.each do |version|
      if version.changeset.present?
        history_item = {}
        history_item[:date] = version.created_at.in_time_zone('Mountain Time (US & Canada)').to_formatted_s(:long)
        if version.whodunnit.present?
          user = User.find(version.whodunnit)
          history_item[:user] = "#{user.name} - #{user.email}"
        else
          history_item[:user] = 'Unknown'
        end

        history_item[:changes] = version.changeset
        history_item[:changes].map do |attribute, change|
          case attribute
          when 'language'
            change.map! { |language| humanize_uri(:language, language) }
          when 'languages'
            change.map! do |change_item|
              next [] if change_item.nil?

              change_item.map do |language|
                humanize_uri(:language, language)
              end
            end

            change.map! { |change_item| change_item.join(', ') }

          when 'institution'
            change.map! { |institution| humanize_uri(:institution, institution) }
          when 'visibility_after_embargo', 'visibility'
            change.map! { |visibility| humanize_uri(:visibility, visibility) }
          when 'item_type'
            previous_version_object = version.reify
            previous_version_type = previous_version_object.item_type_with_status_code
            change[0] = if previous_version_type.present?
                          t("controlled_vocabularies.item_type_with_status.#{previous_version_type}")
                        end

            new_version_object = version.next.reify
            new_version_type = new_version_object.item_type_with_status_code
            change[1] = if new_version_type.present?
                          t("controlled_vocabularies.item_type_with_status.#{new_version_type}")
                        end

          when 'license'
            change.map! { |license| humanize_uri(:license, license) }
          when 'record_created_at', 'date_ingested', 'embargo_end_date', 'date_accepted', 'date_submitted',
            'created_at', 'updated_at'
            change.map! do |date|
              next nil if date.nil?

              date.in_time_zone('Mountain Time (US & Canada)').to_formatted_s(:long)
            end

          when 'member_of_paths'
            change.map! do |change_item|
              next [] if change_item.nil?

              change_item.map do |path|
                community_id, collection_id = path.split('/')
                community_title = Community.find(community_id).title
                collection_title = Collection.find(collection_id).title
                "#{community_title}/#{collection_title}"
              end
            end

            change.map! { |change_item| change_item.join(', ') }

          when 'is_version_of', 'subject', 'departments', 'supervisors', 'committee_members', 'creators',
            'contributors', 'temporal_subjects', 'spatial_subjects', 'publication_status'
            change.map! do |change_item|
              next nil if change_item.nil?

              change_item.join(', ')
            end
          end
          [attribute, change]
        end

        history_item[:changes].delete_if do |change|
          ['logo_id', 'updated_at', 'embargo_history', 'aasm_state'].include? change
        end
        history_item[:changes].transform_keys! do |key|
          next 'Author' if key == 'dissertant'

          key.tr('_', ' ').titlecase
        end
      end
      history << history_item unless history_item.nil? || history_item[:changes].empty?
    end
    history
  end
end
