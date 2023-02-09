class DOIService

  PUBLISHER = 'University of Alberta Library'.freeze
  DATACITE_METADATA_SCHEME = {
    article_published: 'Text/Published Journal Article',
    article_submitted: 'Text/Submitted Journal Article',
    book: 'Text/Book',
    chapter: 'Text/Chapter',
    conference_workshop_presentation: 'Other/Presentation',
    conference_workshop_poster: 'Image/Conference Poster',
    dataset: 'Dataset',
    image: 'Image',
    learning_object: 'Other/Learning Object',
    report: 'Text/Report',
    research_material: 'Other/Research Material',
    review: 'Text/Review',
    thesis: 'Text/Thesis'
  }.freeze
  UNAVAILABLE_MESSAGE = 'unavailable| not publicly released'.freeze

  attr_reader :item

  def initialize(item)
    @item = item.decorate
  end

  def create
    return unless @item.unminted? && !@item.private?

    response = Datacite::Client.mint(datacite_attributes)
    id = "doi:#{response.doi}"

    if response.present?
      @item.tap do |uo|
        uo.doi = id
        uo.save!
      end
      @item.synced!
      response
    end
  rescue StandardError => e
    # Skip the next handle_doi_states after_save callback and roll back
    # the state to it's previous value. By skipping the callback we can prevent
    # it temporarily from queueing another job. As this could make it end up
    # right back here again resulting in an infinite loop. This all works around a bug in ActiveFedora
    # preventing us from skipping this automatically
    @item.skip_handle_doi_states = true
    @item.unpublish!

    raise e
  end

  def update
    return unless @item.awaiting_update?

    if @item.private?
      event = Datacite::Event::HIDE
      reason = UNAVAILABLE_MESSAGE
    else
      event = Datacite::Event::PUBLISH
    end

    response = Datacite::Client.modify(@item.doi.delete_prefix('doi:'), datacite_attributes, event: event,
                                                                                             reason: reason)

    return if response.blank?

    if @item.private?
      @item.unpublish!
    else
      @item.synced!
    end
    response
  rescue StandardError => e
    # Skip the next handle_doi_states after_save callback and roll back
    # the state to it's previous value. By skipping the callback we can prevent
    # it temporarily from queueing another job. As this could make it end up
    # right back here again resulting in an infinite loop. This all works around a bug in ActiveFedora
    # preventing us from skipping this automatically
    @item.skip_handle_doi_states = true
    if @item.private?
      @item.synced!
    else
      @item.unpublish!
    end
    raise e
  end

  def self.remove(doi)
    Datacite::Client.modify(doi.delete_prefix('doi:'),
                            { reason: 'unavailable | withdrawn', event: Datacite::Event::HIDE })
  end

  private

  def datacite_attributes
    {
      creators: @item.authors.map { |author| { name: author } },
      titles: [{
        title: @item.title
      }],
      descriptions: [{
        description: @item.description
      }],
      publisher: PUBLISHER,
      publicationYear: @item.sort_year.presence || '(:unav)',
      types: {
        resourceType: DATACITE_METADATA_SCHEME[@item.item_type_with_status_code],
        resourceTypeGeneral: DATACITE_METADATA_SCHEME[@item.item_type_with_status_code].split('/').first
      },
      url: Rails.application.routes.url_helpers.item_url(id: @item.id),
      schemaVersion: 'http://datacite.org/schema/kernel-4'
    }
  end

end
