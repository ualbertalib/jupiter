module JupiterCore
  extend ActiveSupport::Autoload

  class ObjectNotFound < StandardError; end

  class PropertyInvalidError < StandardError; end

  class MultipleIdViolationError < StandardError; end

  class AlreadyDefinedError < StandardError; end

  class LockedInstanceError < StandardError; end

  class SolrNameManglingError < StandardError; end

  class VocabularyMissingError < StandardError; end

  VISIBILITY_PUBLIC = ControlledVocabulary.era.visibility.public.freeze
  VISIBILITY_PRIVATE = ControlledVocabulary.era.visibility.private.freeze
  VISIBILITY_AUTHENTICATED = ControlledVocabulary.era.visibility.authenticated.freeze

  VISIBILITIES = [VISIBILITY_PUBLIC, VISIBILITY_PRIVATE, VISIBILITY_AUTHENTICATED].freeze
end
