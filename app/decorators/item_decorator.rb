class ItemDecorator < Draper::Decorator

  delegate_all

  def clean_history
    clean_versions.map do |version|
      changes = format_changeset(version.changeset, version)
      changes = h.clean_up_changes(changes)
      next if changes.empty?

      date = version.created_at.in_time_zone('Mountain Time (US & Canada)')
      formatted_date = date.to_formatted_s(:long)
      user_info = h.user_info(version.whodunnit)

      { date: formatted_date, user_info: user_info, changes: changes }
    end.compact.reverse
  end

  private

  def format_changeset(changes, version)
    changes.map do |attribute, change|
      case attribute
      when 'languages'
        h.format_languages_change(change)
      when 'visibility_after_embargo', 'visibility'
        change.map! { |visibility| h.humanize_uri(:visibility, visibility) }
      when 'item_type'
        change = h.format_item_type_change(change, version)
      when 'license'
        change.map! { |license| h.humanize_uri(:license, license) }
      when 'record_created_at', 'date_ingested', 'embargo_end_date', 'created_at', 'updated_at'
        change.map! do |date|
          next nil if date.nil?

          date.in_time_zone('Mountain Time (US & Canada)').to_formatted_s(:long)
        end
      when 'created'
        change.map! do |date|
          next nil if date.nil?

          h.humanize_date(date)
        end
      when 'member_of_paths'
        h.format_member_of_paths_change(change)
      when 'publication_status'
        h.format_publication_status_change(change)
      when 'is_version_of', 'subject', 'creators', 'contributors', 'temporal_subjects', 'spatial_subjects'
        change.map! do |change_item|
          next nil if change_item.nil?

          change_item.join(', ')
        end
      end
      [attribute, h.change_diff(change)]
    end
  end

end
