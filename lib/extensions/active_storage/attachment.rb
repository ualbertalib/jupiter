module ActiveStorageAttachmentExtension
  extend ActiveSupport::Concern

  included do
    acts_as_rdfable
  end
end
