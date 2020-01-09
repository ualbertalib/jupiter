module ActiveStorageBlobExtension
  extend ActiveSupport::Concern

  included do
    acts_as_rdfable

    def signed_id
      key
    end

    def self.find_signed(id)
      find_by(key: id)
    end
  end
end
