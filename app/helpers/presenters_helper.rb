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
    if obj.is_a?(JupiterCore::FacetResult::FacetValue)
      present_facet(obj)
    else
      presenter_for(obj).new(self, obj)
    end
  end

  private

  def present_facet(facet_value)
    @presenter_cache[facet_value] ||= begin
      klass_name = "Presenters::FacetValues::#{facet_value.attribute_name.to_s.camelize}"
      klass_name.constantize
    rescue NameError
      ::Presenters::FacetValues::DefaultPresenter
    end

    @presenter_cache[facet_value].new(self, params[:facets], facet_value)
  end

  def presenter_for(obj)
    @presenter_cache[obj] ||= begin
      klass_name = "Presenters::#{obj.class}"
      klass_name.constantize
    rescue NameError
      raise NoSuchPresenter, "Presenter #{klass_name} is not defined for #{obj}"
    end
  end
  # rubocop:enable Rails/HelperInstanceVariable
end
