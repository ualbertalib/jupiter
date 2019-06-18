module JupiterCore::SolrNameMangler
  SOLR_MANGLED_STEMS_BY_TYPE = {
    path: { pathing: 'dpsim' },
    boolean: { exact_match: 'ssim' },
    date: {
      sort: 'dtsi',
      exact_match: 'ssim'
    },
    integer: {
      search: 'isim',
      sort: 'isi', #singluar
      range_facet: 'isi',  #singluar
      exact_match: 'ssim'
    },
    string: {
      pathing: 'dpsim',
      facet: 'sim',
      search: 'tesim',
      sort: 'ssi',  #singluar
      exact_match: 'ssim'
    },
    text: {
      search: 'tesim'
    }
  }.freeze

  def self.mangled_name_for(name, type:, role:)
    rawtype = (type == :json_array ? :string : type)

    stem = SOLR_MANGLED_STEMS_BY_TYPE.dig(rawtype, role)
    if stem.blank?
      raise JupiterCore::SolrNameManglingError,
            "Unmapped type/role combination for requested mangle of #{name}: type: #{type}, role: #{role}"
    end

    "#{name}_#{stem}"
  end
end
