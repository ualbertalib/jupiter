class HumanizedChangeSet

  TIMEZONE = 'Mountain Time (US & Canada)'.freeze
  attr_reader :html_diffs

  def initialize(helper, version)
    @h = helper
    @version = version
    @changeset = version.changeset
    @whodunnit = version.whodunnit
    @date = version.created_at
    @html_diffs = []
    generate_html_diffs
  end

  def user_info
    if @whodunnit.present?
      user = User.find(@whodunnit)
      user_info = "#{user.name} - #{user.email}"
    else
      user_info = 'Unknown'
    end

    user_info
  end

  def date
    date = @date.in_time_zone(TIMEZONE)
    date.to_formatted_s(:long)
  end

  private

  def generate_html_diffs
    @changeset.each_key do |attribute_name|
      # skip changes to these attributes – we don't care to present them
      next if ['logo_id', 'updated_at', 'embargo_history', 'aasm_state'].include? attribute_name

      transformed_values = begin
        send(attribute_name)
      # No modifications to the changeset needed.
      rescue NoMethodError
        @changeset[attribute_name]
      end

      html_diff = Differ.diff_by_word(transformed_values[1].to_s, transformed_values[0].to_s).format_as(:html)
      # Allowing del and ins html tags as the differ gem uses them to display deleted and inserted text.
      sanitized_html_diff = @h.sanitize(html_diff, tags: ['del', 'ins'])

      # Some attributes have different labels due to preference of Admins.
      attribute_name = case attribute_name
                       when 'dissertant'
                         'Author'
                       else
                         attribute_name.tr('_', ' ').titlecase
                       end

      @html_diffs << { attribute: attribute_name, html: sanitized_html_diff }
    end
  end

  def visibility
    humanize_visibility_attribute(:visibility)
  end

  def visibility_after_embargo
    humanize_visibility_attribute(:visibility_after_embargo)
  end

  def record_created_at
    localize_date_to_timezone(:record_created_at)
  end

  def date_ingested
    localize_date_to_timezone(:date_ingested)
  end

  def embargo_end_date
    localize_date_to_timezone(:embargo_end_date)
  end

  def created_at
    localize_date_to_timezone(:created_at)
  end

  def date_accepted
    localize_date_to_timezone(:date_accepted)
  end

  def date_submitted
    localize_date_to_timezone(:date_submitted)
  end

  # rubocop:disable Naming/PredicateName
  def is_version_of
    concat_array_attribute(:is_version_of)
  end
  # rubocop:enable Naming/PredicateName

  def subject
    concat_array_attribute(:subject)
  end

  def creators
    concat_array_attribute(:creators)
  end

  def contributors
    concat_array_attribute(:contributors)
  end

  def temporal_subjects
    concat_array_attribute(:temporal_subjects)
  end

  def spatial_subjects
    concat_array_attribute(:spatial_subjects)
  end

  def departments
    concat_array_attribute(:departments)
  end

  def supervisors
    concat_array_attribute(:supervisors)
  end

  def committee_members
    concat_array_attribute(:committee_members)
  end

  def graduation_date
    humanize_dates(:graduation_date)
  end

  def creation_date
    humanize_dates(:creation_date)
  end

  def created
    humanize_dates(:created)
  end

  def humanize_visibility_attribute(attribute)
    @changeset[attribute].map { |visibility| @h.humanize_uri(:visibility, visibility) }
  end

  def localize_date_to_timezone(attribute)
    @changeset[attribute].map do |date|
      next nil if date.nil?

      date.in_time_zone(TIMEZONE).to_formatted_s(:long)
    end
  end

  def concat_array_attribute(attribute)
    @changeset[attribute].map do |change_item|
      next nil if change_item.nil?

      change_item.join(', ')
    end
  end

  def humanize_dates(attribute)
    @changeset[attribute].map do |date|
      next nil if date.nil?

      @h.humanize_date(date)
    end
  end

  def member_of_paths
    humanized_member_of_paths = @changeset[:member_of_paths].map do |change_item|
      next [] if change_item.nil?

      change_item.map do |path|
        community_id, collection_id = path.split('/')
        community_title = Community.find(community_id).title
        collection_title = Collection.find(collection_id).title
        "#{community_title}/#{collection_title}"
      end
    end

    humanized_member_of_paths.map { |change_item| change_item.join(', ') }
  end

  def languages
    humanized_languages = @changeset[:languages].map do |change_item|
      next [] if change_item.nil?

      change_item.map do |language|
        @h.humanize_uri(:language, language)
      end
    end

    humanized_languages.map { |change_item| change_item.join(', ') }
  end

  def language
    @changeset[:language].map { |language| @h.humanize_uri(:language, language) }
  end

  def license
    @changeset[:license].map { |license| @h.humanize_uri(:license, license) }
  end

  def institution
    @changeset[:institution].map { |institution| @h.humanize_uri(:institution, institution) }
  end

  def publication_status
    humanized_publication_status = @changeset[:publication_status].map do |change_item|
      next [] if change_item.nil?

      change_item.map do |publication_status|
        CONTROLLED_VOCABULARIES[:publication_status].from_uri(publication_status)
      end
    end

    humanized_publication_status.map { |change_item| change_item.join(', ') }
  end

  def item_type
    humanized_item_type = []
    last_version = @version
    last_version_object = last_version.reify
    last_version_type = last_version_object.item_type_with_status_code
    if last_version_type.present?
      humanized_item_type[0] = I18n.t("controlled_vocabularies.item_type_with_status.#{last_version_type}")
    end

    new_version_object = last_version.next.reify
    new_version_type = new_version_object.item_type_with_status_code
    if new_version_type.present?
      humanized_item_type[1] = I18n.t("controlled_vocabularies.item_type_with_status.#{new_version_type}")
    end

    humanized_item_type
  end

end
