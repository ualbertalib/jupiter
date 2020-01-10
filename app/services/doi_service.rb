class DOIService

  PUBLISHER = 'University of Alberta Libraries'.freeze
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
  UNAVAILABLE_MESSAGE = "#{Ezid::Status::UNAVAILABLE} | not publicly released".freeze

  attr_reader :item

  def initialize(item)
    @item = item
  end

  def create
    return unless @item.unminted? && !@item.private?

    ezid_identifer = Ezid::Identifier.mint(Ezid::Client.config.default_shoulder, ezid_metadata)
    if ezid_identifer.present?
      @item.tap do |uo|
        uo.doi = ezid_identifer.id
        uo.save!
      end
      @item.synced!
      ezid_identifer
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

    ezid_identifer = Ezid::Identifier.modify(@item.doi, ezid_metadata)
    return if ezid_identifer.blank?

    if @item.private?
      @item.unpublish!
    else
      @item.synced!
    end
    ezid_identifer
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
    Ezid::Identifier.modify(doi, status: "#{Ezid::Status::UNAVAILABLE} | withdrawn", export: 'no')
  end

  private

  def ezid_metadata
    {
      datacite_creator: @item.authors.join('; '),
      datacite_publisher: PUBLISHER,
      datacite_publicationyear: @item.sort_year.presence || '(:unav)',
      datacite_resourcetype: DATACITE_METADATA_SCHEME[@item.item_type_with_status_code],
      datacite_resourcetypegeneral: DATACITE_METADATA_SCHEME[@item.item_type_with_status_code].split('/').first,
      datacite_title: @item.title,
      target: Rails.application.routes.url_helpers.item_url(id: @item.id),
      # Can only set status if been minted previously, else its public
      status: @item.private? && @item.doi.present? ? UNAVAILABLE_MESSAGE : Ezid::Status::PUBLIC,
      export: @item.private? ? 'no' : 'yes'
    }
  end

end
