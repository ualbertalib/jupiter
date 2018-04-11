module JupiterCore
  extend ActiveSupport::Autoload

  class ObjectNotFound < StandardError; end
  class PropertyInvalidError < StandardError; end
  class MultipleIdViolationError < StandardError; end
  class AlreadyDefinedError < StandardError; end
  class LockedInstanceError < StandardError; end

  VISIBILITY_PUBLIC = CONTROLLED_VOCABULARIES[:visibility].public.freeze
  VISIBILITY_PRIVATE = CONTROLLED_VOCABULARIES[:visibility].private.freeze
  VISIBILITY_AUTHENTICATED = CONTROLLED_VOCABULARIES[:visibility].authenticated.freeze

  VISIBILITIES = [VISIBILITY_PUBLIC, VISIBILITY_PRIVATE, VISIBILITY_AUTHENTICATED].freeze

  # This'll do for the time being I suppose ¯\_(ツ)_/¯
  VERSION = '1.0.3'.freeze
end
