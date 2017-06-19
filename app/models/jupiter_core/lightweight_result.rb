class JupiterCore::LightweightResult
  def initialize(solr_doc)
    @solr_doc = solr_doc
    @interposed_class = solr_doc['has_model_ssim'].first.constantize
  end

  def reify
    @interposed_class.find(@solr_doc['id'])
  end

  def method_missing(name, *args, &block)
    metadata = @interposed_class.property_metadata(name)
    is_multivalued = metadata[:multiple]
    solr_names = metadata[:solr_names]

    solr_names.each do |name|
      data = @solr_doc[name] if @solr_doc.key?(name)
      if is_multivalued 
        return data 
      else
        return data.first
      end
    end
    super
  end

end