module PresentersHelper
  class NoSuchPresenter < StandardError; end

  # Rubocop now wants us to remove instance methods from helpers. This is a good idea
  # but will require a bit of refactoring. Find other instances of this disabling
  # and fix all at once.
  # rubocop:disable Rails/HelperInstanceVariable
  def present(obj)
    # cache the obj => presenter mappings for the lifetime of the request, to avoid the overhead of
    # string to class conversion dozens of times during facet rendering
    @presenter_cache ||= {}
    # FacetValues are special insofar as they dynamically specify their own presenter per-attribute-name involved
    if obj.is_a?(JupiterCore::SolrServices::FacetResult::FacetValue)
      present_facet(obj)
    else
      presenter_for(obj).decorate(obj)
    end
  end

  private

  def present_facet(facet_value)
    @presenter_cache[facet_value] ||= begin
      klass_name = "Facets::#{facet_value.attribute_name.to_s.camelize}"
      klass_name.constantize
    rescue NameError
      ::Facets::DefaultFacetDecorator
    end

    @presenter_cache[facet_value].new(self, params[:facets], facet_value)
  end

  def presenter_for(obj)
    @presenter_cache[obj] ||= begin
      klass_name = "Models::#{obj.class}Decorator"
      klass_name.constantize
    rescue NameError
      raise NoSuchPresenter, "Draper-derived Decorator #{klass_name} is not defined for #{obj}"
    end
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

  def format_publication_status_change(change)
    change.map! do |change_item|
      next [] if change_item.nil?

      change_item.map do |publication_status|
        CONTROLLED_VOCABULARIES[:publication_status].from_uri(publication_status)
      end
    end

    change.map! { |change_item| change_item.join(', ') }
  end

  def format_item_type_change(change, version)
    last_version = version
    last_version_object = last_version.reify
    last_version_type = last_version_object.item_type_with_status_code
    if last_version_type.present?
      change[0] = I18n.t("controlled_vocabularies.item_type_with_status.#{last_version_type}")
    end

    new_version_object = last_version.next.reify
    new_version_type = new_version_object.item_type_with_status_code
    change[1] = I18n.t("controlled_vocabularies.item_type_with_status.#{new_version_type}") if new_version_type.present?

    change
  end

  def change_diff(change)
    Differ.diff_by_word(change[1].to_s, change[0].to_s).format_as(:html)
  end

  def user_info(whodunnit)
    if whodunnit.present?
      user = User.find(whodunnit)
      user_info = "#{user.name} - #{user.email}"
    else
      user_info = 'Unknown'
    end

    user_info
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
  # rubocop:enable Rails/HelperInstanceVariable
end
