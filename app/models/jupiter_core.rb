module JupiterCore
  extend ActiveSupport::Autoload

  class ObjectNotFound < StandardError; end

  class PropertyInvalidError < StandardError; end

  class MultipleIdViolationError < StandardError; end

  class AlreadyDefinedError < StandardError; end

  class LockedInstanceError < StandardError; end

  class SolrNameManglingError < StandardError; end

  class VocabularyMissingError < StandardError; end

  class SolrBadRequestError < StandardError; end

  VISIBILITY_PUBLIC = ControlledVocabulary.jupiter_core.visibility.public.freeze
  VISIBILITY_PRIVATE = ControlledVocabulary.jupiter_core.visibility.private.freeze
  VISIBILITY_AUTHENTICATED = ControlledVocabulary.jupiter_core.visibility.authenticated.freeze
  VISIBILITIES = [VISIBILITY_PUBLIC, VISIBILITY_PRIVATE, VISIBILITY_AUTHENTICATED].freeze
end
