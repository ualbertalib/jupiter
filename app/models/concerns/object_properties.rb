module ObjectProperties
  extend ActiveSupport::Concern

  included do
    # Dublin Core attributes
    has_attribute :title, ::RDF::Vocab::DC.title, solrize_for: [:search, :sort]

    # UAL attributes
    has_attribute :fedora3_uuid, ::TERMS[:ual].fedora3UUID, solrize_for: :exact_match
    has_attribute :depositor, ::TERMS[:ual].depositor, solrize_for: [:search]

    unlocked do
      validates :title, presence: true
    end
  end
end
