module ItemHistoryHelper
  def clean_history(edit_history)
    edit_history.map do |edit_history_item|
      version = PaperTrail::Version.find_by(id: edit_history_item[:version_id])
      changes = format_changeset(edit_history_item[:changes], version)
      changes = clean_up_changes(changes)
      next if changes.empty?

      date = version.created_at.in_time_zone('Mountain Time (US & Canada)')
      formatted_date = date.to_formatted_s(:long)
      whodunnit = version.whodunnit
      if whodunnit.present?
        user = User.find(whodunnit)
        user_info = "#{user.name} - #{user.email}"
      else
        user_info = 'Unknown'
      end
      { date: formatted_date, user_info: user_info, changes: changes }
    end.compact.reverse
  end

  def change_diff(change)
    change_text = Differ.diff_by_word(change[1].to_s, change[0].to_s).format_as(:html)
    sanitize(change_text, tags: ['del', 'ins'])
  end

  private

  def format_changeset(changes, version)
    changes.map do |attribute, change|
      case attribute
      when 'language'
        change.map! { |language| humanize_uri(:language, language) }
      when 'languages'
        format_languages_change(change)
      when 'institution'
        change.map! { |institution| humanize_uri(:institution, institution) }
      when 'visibility_after_embargo', 'visibility'
        change.map! { |visibility| humanize_uri(:visibility, visibility) }
      when 'item_type'
        change = format_item_type_change(change, version)
      when 'license'
        change.map! { |license| humanize_uri(:license, license) }
      when 'record_created_at', 'date_ingested', 'embargo_end_date', 'date_accepted', 'date_submitted',
        'created_at', 'updated_at'
        change.map! do |date|
          next nil if date.nil?

          date.in_time_zone('Mountain Time (US & Canada)').to_formatted_s(:long)
        end

      when 'member_of_paths'
        format_member_of_paths_change(change)

      when 'is_version_of', 'subject', 'departments', 'supervisors', 'committee_members', 'creators',
        'contributors', 'temporal_subjects', 'spatial_subjects', 'publication_status'
        change.map! do |change_item|
          next nil if change_item.nil?

          change_item.join(', ')
        end
      end
      [attribute, change]
    end
  end

  def clean_up_changes(changes)
    clean_changes = changes.to_h
    clean_changes.delete_if do |change|
      ['logo_id', 'updated_at', 'embargo_history', 'aasm_state'].include? change
    end
    clean_changes.transform_keys! do |key|
      next 'Author' if key == 'dissertant'

      key.tr('_', ' ').titlecase
    end

    clean_changes
  end

  def format_member_of_paths_change(change)
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
  end

  def format_languages_change(change)
    change.map! do |change_item|
      next [] if change_item.nil?

      change_item.map do |language|
        humanize_uri(:language, language)
      end
    end

    change.map! { |change_item| change_item.join(', ') }
  end

  def format_item_type_change(change, version)
    last_version = version
    last_version_object = last_version.reify
    last_version_type = last_version_object.item_type_with_status_code
    change[0] = t("controlled_vocabularies.item_type_with_status.#{last_version_type}") if last_version_type.present?

    new_version_object = last_version.next.reify
    new_version_type = new_version_object.item_type_with_status_code
    change[1] = t("controlled_vocabularies.item_type_with_status.#{new_version_type}") if new_version_type.present?

    change
  end
end
