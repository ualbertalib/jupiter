class Thesis < JupiterCore::LockedLdpObject

  include CommonObjectProperties
  include CommonItemProperties

  # Dublin Core attributes
  has_attribute :abstract, ::RDF::Vocab::DC.abstract, type: :text, solrize_for: :search
  # Note: language is single-valued for Thesis, but languages is multi-valued for Item
  has_attribute :language, ::RDF::Vocab::DC.language, solrize_for: [:search, :facet]
  has_attribute :date_accepted, ::RDF::Vocab::DC.dateAccepted, type: :date, solrize_for: :exact_match
  has_attribute :date_submitted, ::RDF::Vocab::DC.dateSubmitted, type: :date, solrize_for: :exact_match

  # BIBO
  has_attribute :degree, ::RDF::Vocab::BIBO.degree, solrize_for: :exact_match

  # SWRC
  has_attribute :institution, TERMS[:swrc].institution, solrize_for: :exact_match

  # UAL attributes
  # This one is faceted in `all_contributors`, along with the Item creators/contributors
  has_attribute :dissertant, TERMS[:ual].dissertant, solrize_for: [:search, :sort]
  has_attribute :graduation_date, TERMS[:ual].graduationDate, type: :date, solrize_for: [:search, :sort]
  has_attribute :thesis_level, TERMS[:ual].thesisLevel, solrize_for: :exact_match
  has_attribute :proquest, TERMS[:ual].proquest, solrize_for: :exact_match
  has_attribute :unicorn, TERMS[:ual].unicorn, solrize_for: :exact_match
  has_multival_attribute :committee_member, TERMS[:ual].committeeMember, solrize_for: :exact_match
  has_multival_attribute :department, TERMS[:ual].department, solrize_for: :search
  has_multival_attribute :specialization, TERMS[:ual].specialization, solrize_for: :search
  has_multival_attribute :supervisor, TERMS[:ual].supervisor, solrize_for: :exact_match

  # This gets mixed with the item types for `Item`
  additional_search_index :item_type_with_status,
                          solrize_for: :facet,
                          as: -> { 'thesis' }

  # Dissertants are indexed with the Item creators/contributors
  additional_search_index :all_contributors, solrize_for: :facet, as: -> { [dissertant] }

  unlocked do
    validates :dissertant, presence: true
    validates :graduation_date, presence: true
    validate :language_validations
    validate :institution_validations

    type [::Hydra::PCDM::Vocab::PCDMTerms.Object, ::RDF::Vocab::BIBO.Thesis]

    before_validation do
      # Note: for Item, the sort_year attribute is derived from dcterms:created
      begin
        self.sort_year = Date.parse(graduation_date).year.to_s if graduation_date.present?
      rescue ArgumentError
        # date was unparsable, try to pull out the first 4 digit number as a year
        capture = graduation_date.scan(/\d{4}/)
        self.sort_year = capture[0] if capture.present?
      end
    end

    def language_validations
      uri_validation(language, :language) if language.present?
    end

    def institution_validations
      uri_validation(institution, :institution) if institution.present?
    end
  end

end
