module ActiveStorageAttachmentExtension

  extend ActiveSupport::Concern

  included do
    acts_as_rdfable

    def test
      "test attach"
    end

  end
end