class Thesis < JupiterCore::LockedLdpObject

  include ObjectProperties
  include ItemProperties
  # Needed for ActiveStorage (logo)...
  include GlobalID::Identification
  ldp_object_includes Hydra::Works::WorkBehavior

  # Dublin Core attributes
  has_attribute :abstract, ::RDF::Vocab::DC.abstract, type: :text, solrize_for: :search
  # Note: language is single-valued for Thesis, but languages is multi-valued for Item
  # See below for faceting
  has_attribute :language, ::RDF::Vocab::DC.language, solrize_for: :search
  has_attribute :date_accepted, ::RDF::Vocab::DC.dateAccepted, type: :date, solrize_for: :exact_match
  has_attribute :date_submitted, ::RDF::Vocab::DC.dateSubmitted, type: :date, solrize_for: :exact_match

  # BIBO
  has_attribute :degree, ::RDF::Vocab::BIBO.degree, solrize_for: :exact_match

  # SWRC
  has_attribute :institution, TERMS[:swrc].institution, solrize_for: :exact_match

  # UAL attributes
  # This one is faceted in `all_contributors`, along with the Item creators/contributors
  has_attribute :dissertant, TERMS[:ual].dissertant, solrize_for: [:search, :sort]
  has_attribute :graduation_date, TERMS[:ual].graduationDate, solrize_for: [:search, :sort]
  has_attribute :thesis_level, TERMS[:ual].thesisLevel, solrize_for: :exact_match
  has_attribute :proquest, TERMS[:ual].proquest, solrize_for: :exact_match
  has_attribute :unicorn, TERMS[:ual].unicorn, solrize_for: :exact_match
  has_attribute :specialization, TERMS[:ual].specialization, solrize_for: :search
  has_attribute :departments, TERMS[:ual].departmentList, type: :json_array, solrize_for: [:search]
  has_multival_attribute :committee_members, TERMS[:ual].committeeMember, solrize_for: :exact_match
  has_multival_attribute :unordered_departments, TERMS[:ual].department, solrize_for: :search
  has_multival_attribute :supervisors, TERMS[:ual].supervisor, solrize_for: :exact_match

  # This gets mixed with the item types for `Item`
  additional_search_index :item_type_with_status,
                          solrize_for: :facet,
                          as: -> { item_type_with_status_code }

  # Dissertants are indexed with the Item creators/contributors
  additional_search_index :all_contributors, solrize_for: :facet, as: -> { [dissertant] }

  # Index subjects with Item subjects (topical, temporal, etc).
  additional_search_index :all_subjects, solrize_for: :facet, as: -> { subject }

  # Making `language` consistent with Item `languages`
  additional_search_index :languages,
                          solrize_for: :facet,
                          as: -> { [language] }
  def item_type_with_status_code
    # Keeping a consistent interface as Item
    'thesis'
  end

  unlocked do
    before_save :copy_departments_to_unordered_predicate

    validates :dissertant, presence: true
    validates :graduation_date, presence: true
    validates :sort_year, presence: true
    validates :language, uri: { in_vocabulary: :language }
    validates :institution, uri: { in_vocabulary: :institution }

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

      def copy_departments_to_unordered_predicate
        return unless departments_changed?
        self.unordered_departments = []
        departments.each { |d| self.unordered_departments += [d] }
      end
    end
  end

end
