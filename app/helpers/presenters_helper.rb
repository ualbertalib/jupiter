module PresentersHelper

  class NoSuchPresenter < StandardError; end;

  def present(obj)
    # FacetValues are special insofar as they dynamically specify their own presenter per-attribute-name involved
    if obj.is_a?(JupiterCore::FacetResult::FacetValue)
      present_facet(obj)
    else
      presenter_for(obj).new(self, obj)
    end
  end

  def present_facet(facet_value)
    klass_name = "Presenters::FacetValues::#{facet_value.attribute_name.to_s.camelize}"

    klass = begin
      klass_name.constantize
    rescue NameError
      ::Presenters::FacetValues::DefaultPresenter
    end

    klass.new(self, params[:facets], facet_value)
  end

  private

  def presenter_for(obj)
    klass_name = "Presenters::#{obj.class}"
    klass_name.constantize
  rescue NameError
    raise NoSuchPresenter, "Presenter #{klass_name} is not defined for #{obj}"
  end
end
