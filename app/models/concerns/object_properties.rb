module ObjectProperties
  extend ActiveSupport::Concern

  included do
    extend JupiterCore::ActiveStorageMacros
    # Dublin Core attributes
    has_attribute :title, ::RDF::Vocab::DC.title, solrize_for: [:search, :sort]

    # UAL attributes
    has_attribute :fedora3_uuid, ::TERMS[:ual].fedora3_uuid, solrize_for: :exact_match
    has_attribute :depositor, ::TERMS[:ual].depositor, solrize_for: [:search]

    default_sort index: :title, direction: :asc

    unlocked do
      validates :title, presence: true
    end
  end
end
