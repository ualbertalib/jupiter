class ThesisDecorator < Draper::Decorator

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

  def format_changeset(changes, _version)
    changes.map do |attribute, change|
      case attribute
      when 'language'
        change.map! { |language| h.humanize_uri(:language, language) }
      when 'institution'
        change.map! { |institution| h.humanize_uri(:institution, institution) }
      when 'visibility_after_embargo', 'visibility'
        change.map! { |visibility| h.humanize_uri(:visibility, visibility) }
      when 'record_created_at', 'date_ingested', 'embargo_end_date', 'date_accepted', 'date_submitted', 'created_at',
        'updated_at'
        change.map! do |date|
          next nil if date.nil?

          date.in_time_zone('Mountain Time (US & Canada)').to_formatted_s(:long)
        end
      when 'member_of_paths'
        h.format_member_of_paths_change(change)
      when 'is_version_of', 'subject', 'departments', 'supervisors', 'committee_members'
        change.map! do |change_item|
          next nil if change_item.nil?

          change_item.join(', ')
        end
      end
      [attribute, h.change_diff(change)]
    end
  end

end
