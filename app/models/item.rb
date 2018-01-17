class Item < JupiterCore::LockedLdpObject

  include ObjectProperties
  include ItemProperties
  ldp_object_includes Hydra::Works::WorkBehavior

  ALLOWED_LICENSES = (CONTROLLED_VOCABULARIES[:license] + CONTROLLED_VOCABULARIES[:old_license]).freeze

  # Contributors (faceted in `all_contributors`)
  has_multival_attribute :creators, ::RDF::Vocab::DC11.creator, solrize_for: [:search]
  has_multival_attribute :contributors, ::RDF::Vocab::DC11.contributor, solrize_for: [:search]

  has_attribute :created, ::RDF::Vocab::DC.created, solrize_for: [:search, :sort]

  # Subject types (see `all_subjects` for faceting)
  has_multival_attribute :temporal_subjects, ::RDF::Vocab::DC.temporal, solrize_for: [:search]
  has_multival_attribute :spatial_subjects, ::RDF::Vocab::DC.spatial, solrize_for: [:search]

  has_attribute :description, ::RDF::Vocab::DC.description, type: :text, solrize_for: :search
  has_attribute :publisher, ::RDF::Vocab::DC.publisher, solrize_for: [:search, :facet]
  # has_attribute :date_modified, ::RDF::Vocab::DC.modified, type: :date, solrize_for: :sort
  has_multival_attribute :languages, ::RDF::Vocab::DC.language, solrize_for: [:search, :facet]
  has_attribute :license, ::RDF::Vocab::DC.license, solrize_for: [:search]

  # `type` is an ActiveFedora keyword, so we call it `item_type`
  # Note also the `item_type_with_status` below for searching, faceting and forms
  has_attribute :item_type, ::RDF::Vocab::DC.type, solrize_for: :exact_match
  has_attribute :source, ::RDF::Vocab::DC.source, solrize_for: :exact_match
  has_attribute :related_link, ::RDF::Vocab::DC.relation, solrize_for: :exact_match

  # Bibo attributes
  # This status is only for articles: either 'published' (alone) or two triples for 'draft'/'submitted'
  has_multival_attribute :publication_status, ::RDF::Vocab::BIBO.status, solrize_for: :exact_match

  # Solr only
  additional_search_index :doi_without_label, solrize_for: :exact_match,
                                              as: -> { doi.gsub('doi:', '') if doi.present? }

  # This combines both the controlled vocabulary codes from item_type and published_status above
  # (but only for items that are articles)
  additional_search_index :item_type_with_status,
                          solrize_for: :facet,
                          as: -> { item_type_with_status_code }

  # Combine creators and contributors for faceting (Thesis also uses this index)
  # Note that contributors is converted to an array because it can be nil
  additional_search_index :all_contributors, solrize_for: :facet, as: -> { creators + contributors.to_a }

  # Combine all the subjects for faceting
  additional_search_index :all_subjects, solrize_for: :facet, as: -> { all_subjects }

  # This is stored in solr: combination of item_type and publication_status
  def item_type_with_status_code
    return nil if item_type.blank?
    # Return the item type code unless it's an article, then append publication status code
    item_type_code = CONTROLLED_VOCABULARIES[:item_type].uri_to_code(item_type)
    return item_type_code unless item_type_code == 'article'
    return nil if publication_status.blank?
    publication_status_code = CONTROLLED_VOCABULARIES[:publication_status].uri_to_code(publication_status.first)
    # Next line of code means that 'article_submitted' exists, but 'article_draft' doesn't ("There can be only one!")
    publication_status_code = 'submitted' if publication_status_code == 'draft'
    "#{item_type_code}_#{publication_status_code}"
  rescue ArgumentError
    return nil
  end

  def all_subjects
    subject + temporal_subjects.to_a + spatial_subjects.to_a
  end

  unlocked do
    validates :languages, presence: true
    validates :item_type, presence: true
    validates :subject, presence: true
    validates :creators, presence: true
    validate :language_validations
    validate :license_and_rights_validations
    validate :item_type_and_publication_status_validations

    before_validation do
      begin
        self.sort_year = Date.parse(created).year.to_s if created.present?
      rescue ArgumentError
        # date was unparsable, try to pull out the first 4 digit number as a year
        capture = created.scan(/\d{4}/)
        self.sort_year = capture[0] if capture.present?
      end
    end

    def language_validations
      languages.each do |lang|
        uri_validation(lang, :languages, :language)
      end
    end

    def license_and_rights_validations
      # Must have one of license or rights, not both
      if license.blank?
        errors.add(:base, :need_either_license_or_rights) if rights.blank?
      else
        # Controlled vocabulary check, made more complicated by legacy licenses
        unless ALLOWED_LICENSES.any? { |term| term[:uri] == license }
          errors.add(:license, :not_recognized)
        end
        errors.add(:base, :not_both_license_and_rights) if rights.present?
      end
    end

    def item_type_and_publication_status_validations
      return unless uri_validation(item_type, :item_type)
      code = CONTROLLED_VOCABULARIES[:item_type].uri_to_code(item_type)
      if code == 'article'
        if publication_status.blank?
          errors.add(:publication_status, :required_for_article)
        else
          begin
            # Complication: need either 'published' alone or 'draft' and 'submitted' together
            statuses = publication_status.map do |status|
              CONTROLLED_VOCABULARIES[:publication_status].uri_to_code(status)
            end.sort
            if statuses != ['published'] && statuses != ['draft', 'submitted']
              errors.add(:publication_status, :not_recognized)
            end
          rescue ArgumentError
            errors.add(:publication_status, :not_recognized)
          end
        end
      elsif publication_status.present?
        errors.add(:publication_status, :must_be_absent_for_non_articles)
      end
    end
  end

end
