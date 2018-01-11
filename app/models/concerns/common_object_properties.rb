module CommonObjectProperties
  extend ActiveSupport::Concern

  included do
    ldp_object_includes Hydra::Works::WorkBehavior

    # Dublin Core attributes
    has_attribute :title, ::RDF::Vocab::DC.title, solrize_for: [:search, :sort]

    # UAL attributes
    has_attribute :fedora3_uuid, ::TERMS[:ual].fedora3uuid, solrize_for: :exact_match
    has_attribute :depositor, ::TERMS[:ual].depositor, solrize_for: [:search]

    unlocked do
      validates :title, presence: true
    end
  end
end
