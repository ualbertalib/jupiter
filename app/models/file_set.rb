class FileSet < JupiterCore::LockedLdpObject

  has_solr_exporter Exporters::Solr::FileSetExporter

  # TODO: Should move embargo visibility up into LockedLdpObject
  VISIBILITY_EMBARGO = CONTROLLED_VOCABULARIES[:visibility].embargo.freeze

  ldp_object_includes Hydra::Works::FileSetBehavior

  has_attribute :contained_filename, ::RDF::Vocab::DC.title
  has_attribute :sitemap_link, ::TERMS[:ual].sitemap_link

  belongs_to :item, using_existing_association: :member_of_collections

  def owning_item
    JupiterCore::LockedLdpObject.find(item, types: [Item, Thesis])
  end

  # TODO: Should move embargo visibility up into LockedLdpObject
  def self.valid_visibilities
    super + [VISIBILITY_EMBARGO]
  end

  unlocked do
    def fetch_raw_original_file_data(&block)
      fetch_raw_file_data(original_file.uri, &block)
    end

    def fetch_raw_thumbnail_data(&block)
      fetch_raw_file_data(thumbnail.uri, &block)
    end

    private

    def fetch_raw_file_data(rdf_uri)
      # don't ask. RDF::URIs aren't real Ruby URIs for reasons that presumably made sense to someone, somewhere
      uri = URI.parse(rdf_uri.to_s)
      Net::HTTP.start(uri.host, uri.port, use_ssl: (uri.scheme == 'https')) do |http|
        req = Net::HTTP::Get.new uri, ldp_source.client.http.headers
        http.request(req) do |response|
          case response
          when Net::HTTPSuccess
            yield response.content_type, StringIO.new(response.body)
          else
            raise "Could not fetch #{uri}. Fedora responded with: #{response.code}, #{response.body}"
          end
        end
      end
    end
  end

end
