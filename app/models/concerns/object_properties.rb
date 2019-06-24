module ObjectProperties
  extend ActiveSupport::Concern

  included do
    extend JupiterCore::ActiveStorageMacros
    # Dublin Core attributes
    has_attribute :title, ::RDF::Vocab::DC.title

    # UAL attributes
    has_attribute :fedora3_uuid, ::TERMS[:ual].fedora3_uuid
    has_attribute :depositor, ::TERMS[:ual].depositor

    default_sort index: :title, direction: :asc

    unlocked do
      validates :title, presence: true
    end
  end
end
