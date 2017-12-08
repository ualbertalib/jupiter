class JupiterCore::Search

  # How dumb is this? Seems pretty dumb, but that's the official recommendation I guess:
  # https://wiki.apache.org/solr/CommonQueryParameters
  MAX_RESULTS = 10_000_000

  # Performs a solr search using the given query and filtered query strings.
  # Returns an instance of +DeferredFacetedSolrQuery+ providing result counts, +LockedLDPObject+ representing results,
  # and access to result facets. Results are lazily generated when you attempt to enumerate them, so that you can
  # chain this call with pagination, sorting, etc
  #
  # TODO: probably someone will request not showing some of the default facets in some context,
  # so one potential path forward would be to add a facet exclusions param and subtract it out of the facet_fields
  # when creating the DeferredFacetedSolrQuery
  def self.faceted_search(q: '', facets: [], models: [], as: nil)
    raise ArgumentError, 'as: must specify a user!' if as.present? && !as.is_a?(User)
    raise ArgumentError, 'must provide at least one model to search for!' if models.blank?
    models = [models] unless models.is_a?(Array)
    facets = [] if facets.blank?

    base_query = []
    ownership_query = calculate_ownership_query(as)

    # Our query permissions are white-list based. You only get public results unless the results of +calculate_ownership_query+
    # assign you additional permissions based on the user passed to it.
    base_query << %Q((_query_:"{!raw f=visibility_ssim}#{JupiterCore::VISIBILITY_PUBLIC}"#{ownership_query}))
    base_query << q if q.present?

    fq = []
    facets.each do |key, value|
      fq << %Q(#{key}: "#{value}")
    end

    # queried fields, by default, are all of the fields marked as :search (see calculate_queried_fields).
    # We can revist if we need to customize this more granularly
    JupiterCore::DeferredFacetedSolrQuery.new(q: base_query, fq: fq.join(' AND '),
                                              qf: calculate_queried_fields(models),
                                              facet_map: construct_facet_map(models),
                                              facet_fields: models.map(&:facets).flatten.uniq,
                                              restrict_to_model: models.map { |m| m.send(:derived_af_class) })
  end

  # derive additional restriction or broadening of the visibilitily query on top of the default
  # "where visibility is public" restriction
  def self.calculate_ownership_query(user)
    # non-logged-in users don't get anything else
    return '' if user.blank?

    # You can see what you own, regardless of visibility
    # TODO: owner is...? db id? ccid? email?
    return %Q( OR _query_:"{!raw f=owner_ssim}#{user.id}") unless user.admin?

    # make any visibility setting, including a missing visibility specifier, visible to admins
    #
    # this translates into non-insane query language as "OR visibility is null ([* TO *] AND *:*") OR visibility
    # is any non-null value (*)
    ' OR _query_:"-visibility_ssim:[* TO *] AND *:*" OR _query_:"visibility_ssim:*"'
  end

  def self.perform_solr_query(q:, qf: '', fq: '', facet: false, facet_fields: [],
                              restrict_to_model: nil, rows: MAX_RESULTS, start: nil, sort: nil)
    query = []
    restrict_to_model = [restrict_to_model] unless restrict_to_model.is_a?(Array)

    model_scopes = []

    restrict_to_model.each do |model|
      model_scopes << %Q(_query_:"{!raw f=has_model_ssim}#{model.name}")
    end

    query << "(#{model_scopes.join(' OR ')})"

    query.append(q) if q.present?

    params = {
      q: query.join(' AND '),
      qf: qf,
      fq: fq,
      facet: facet,
      rows: rows,
      'facet.field': facet_fields
    }

    params[:start] = start if start.present?
    params[:sort] = sort if sort.present?

    response = ActiveFedora::SolrService.instance.conn.get('select', params: params)

    raise SearchFailed unless response['responseHeader']['status'] == 0

    [response['response']['numFound'], response['response']['docs'], response['facet_counts']]
  end

  class << self

    private

    # Solr's "qf" indicates the solr index names of every field to be searched, separated by a blank space
    # note that we are not adding scores here, meaning the default weightings are used
    def calculate_queried_fields(models)
      queried_fields = []
      models.each do |model|
        model.attribute_cache.each_value do |properties|
          idx = properties[:solrize_for].find_index(:search)
          queried_fields << properties[:solr_names][idx] if idx.present?
        end
        model.solr_calc_attributes.each_value do |solr_properties|
          idx = solr_properties.find_index(:search)
          queried_fields << solr_properties[:solr_names][idx] if idx.present?
        end
      end
      queried_fields.uniq.join(' ')
    end

    # combine the facet maps (solr_name => attribute_name) of all of the models being searched
    def construct_facet_map(models)
      models.map(&:reverse_solr_name_cache).reduce(&:merge)
    end

  end

end
