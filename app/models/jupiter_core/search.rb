class JupiterCore::Search

  # Official recommendation to return all results in a single page: set to number higher than possible number of results
  # https://web.archive.org/web/20190405125211/https://wiki.apache.org/solr/CommonQueryParameters
  MAX_RESULTS = 10_000_000

  # Maximum number of facet results to retrieve per Facet
  MAX_FACETS_RETURNED = 10

  # Performs a solr search using the given query and filtered query strings.
  # Returns an instance of +DeferredFacetedSolrQuery+ providing result counts, +LockedLDPObject+ representing results,
  # and access to result facets. Results are lazily generated when you attempt to enumerate them, so that you can
  # chain this call with pagination, sorting, etc
  #
  # TODO: probably someone will request not showing some of the default facets in some context,
  # so one potential path forward would be to add a facet exclusions param and subtract it out of the facet_fields
  # when creating the DeferredFacetedSolrQuery
  def self.faceted_search(q: '', facets: [], ranges: [], models: [], as: nil, fulltext: false)
    raise ArgumentError, 'as: must specify a user!' if as.present? && !as.is_a?(User)
    raise ArgumentError, 'must provide at least one model to search for!' if models.blank?

    models = [models] unless models.is_a?(Array)
    facets = [] if facets.blank?
    ranges = {} if ranges.blank?

    base_query = []
    fq = []
    ownership_query = calculate_ownership_query(as)

    # Our query permissions are allowlist based. You only get public results unless the results of +calculate_ownership_query+
    # assign you additional permissions based on the user passed to it.

    # Why can't I split %Q() strings over multiple lines? Seems incorrect
    # rubocop:disable Layout/LineLength
    fq << %Q((visibility_ssim:"#{JupiterCore::VISIBILITY_PUBLIC}" OR visibility_ssim:"#{JupiterCore::VISIBILITY_AUTHENTICATED}"#{ownership_query}))
    # rubocop:enable Layout/LineLength

    base_query << q if q.present?
    facets.each do |key, values|
      fq << %Q(#{key}:\(#{values.collect { |value| "\"#{value}\"" }.join(' OR ')}\))
    end
    ranges.each do |key, value|
      fq << "#{key}:[#{value[:begin]} TO #{value[:end]}]"
    end

    fulltext_fields = construct_fulltext_fields(models) if fulltext

    # queried fields, by default, are all of the fields marked as :search (see calculate_queried_fields).
    # We can revist if we need to customize this more granularly
    JupiterCore::SolrServices::DeferredFacetedSolrQuery.new(q: base_query,
                                                            fq: fq.join(' AND '),
                                                            qf: calculate_queried_fields(models),
                                                            facet_map: construct_facet_map(models),
                                                            facet_fields: construct_facet_fields(models, user: as),
                                                            ranges:,
                                                            restrict_to_model: models,
                                                            fulltext_fields:)
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
    # this translates into a sensible query language as "OR visibility is null ([* TO *] AND *:*") OR visibility
    # is any non-null value (*)
    ' OR _query_:"-visibility_ssim:[* TO *] AND *:*" OR _query_:"visibility_ssim:*"'
  end

  def self.perform_solr_query(q:, qf: '', fq: '', facet: false, facet_fields: [], facet_max: MAX_FACETS_RETURNED,
                              restrict_to_model: nil, rows: MAX_RESULTS, start: nil, sort: nil, fulltext_fields: [])
    params = prepare_solr_query(q:, qf:, fq:, facet:, facet_fields:, facet_max:,
                                restrict_to_model:, rows:,
                                start:, sort:, fulltext_fields:)

    response = begin
      JupiterCore::SolrServices::Client.instance.connection.get('select', params:)
    rescue RSolr::Error::Http => e
      raise JupiterCore::SolrBadRequestError if e.response[:status] == 400

      raise
    end

    raise SearchFailed unless response['responseHeader']['status'] == 0

    [response['response']['numFound'], response['response']['docs'], response['facet_counts'], response['highlighting']]
  end

  def self.prepare_solr_query(q:, qf: '', fq: '', facet: false, facet_fields: [], facet_max: MAX_FACETS_RETURNED,
                              restrict_to_model: nil, rows: MAX_RESULTS, start: nil, sort: nil, fulltext_fields: [])
    query = []
    restrict_to_model = [restrict_to_model] unless restrict_to_model.is_a?(Array)

    model_scopes = []

    restrict_to_model.compact.each do |model|
      model_name = model_to_name(model)
      model_scopes << %Q(_query_:"{!raw f=has_model_ssim}#{model_name}")
    end
    fquery = []
    fquery << "(#{model_scopes.join(' OR ')})" if model_scopes.present?

    query.append(q) if q.present?
    fquery.append(fq) if fq.present?

    params = {
      q: query.join(' AND '),
      qf:,
      fq: fquery.join(' AND '),
      facet:,
      rows:,
      'facet.field': facet_fields,
      'facet.limit': facet_max
    }

    if fulltext_fields.present?
      params.merge!({
                      hl: true,
                      'hl.fl': fulltext_fields,
                      'hl.snippets': 3,
                      'hl.fragsize': 300,
                      'hl.simple.pre': '<mark>',
                      'hl.simple.post': '</mark>'
                    })
    end

    params[:start] = start if start.present?
    params[:sort] = sort if sort.present?

    params
  end

  class << self

    private

    # Solr's "qf" indicates the solr index names of every field to be searched, separated by a blank space
    # note that we are not adding scores here, meaning the default weightings are used
    def calculate_queried_fields(models)
      queried_fields = []
      models.each do |model|
        queried_fields += model.solr_exporter_class.searched_solr_names
      end
      queried_fields.uniq.join(' ')
    end

    # combine the facet maps (solr_name => attribute_name) of all of the models being searched
    def construct_facet_map(models)
      models.map do |model|
        model.solr_exporter_class.reverse_solr_name_map
      end.reduce(&:merge)
    end

    # Disallow use of the visibility facet by non-admins
    def construct_facet_fields(models, user:)
      # the visibility facet is defined identically in all models
      visibility_facet = models.first.solr_exporter_class.solr_name_for(:visibility, role: :facet)
      facets = models.map do |model|
        model.solr_exporter_class.facets
      end.flatten.uniq
      user&.admin? ? facets : facets.reject { |f| f == visibility_facet }
    end

    def construct_fulltext_fields(models)
      models.map do |model|
        next if model.solr_exporter_class.fulltext_searchable_field.blank?

        model.solr_exporter_class.fulltext_searchable_mangled_solr_name
      end.uniq
    end

    def model_to_name(model)
      if model.name.start_with?('IR')
        model.name
      else
        "Ar#{model.name}"
      end
    end

  end

end
