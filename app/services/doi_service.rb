
# class for interacting with DOI API using EZID
class DOIService

  PUBLISHER = 'University of Alberta Libraries'.freeze
  DATACITE_METADATA_SCHEME = {
    book: 'Text/Book',
    chapter: 'Text/Chapter',
    conference_poster: 'Image/Conference Poster',
    conference_paper: 'Other/Presentation',
    dataset: 'Dataset',
    image: 'Image',
    article_submitted: 'Text/Submitted Journal Article',
    article_published: 'Text/Published Journal Article',
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
    return unless @item.doi_state.unminted? && !@item.private?
    ezid_identifer = Ezid::Identifier.mint(Ezid::Client.config.default_shoulder, doi_metadata)
    if ezid_identifer.present?
      @item.unlock_and_fetch_ldp_object {|uo| uo.doi = ezid_identifer.id; uo.save!}
      @item.doi_state.synced!
      ezid_identifer
    end
    # EZID API call has probably failed so let's roll back to previous state change
  rescue StandardError => e
    # Skip the next handle_doi_states after_save callback and roll back
    # the state to it's previous value. By skipping the callback we can prevent
    # it temporarily from queueing another job. As this could make it end up
    # right back here again resulting in an infinite loop.
    @item.skip_handle_doi_states = true
    @item.doi_state.unpublish!

    raise e
  end

  def update
    return unless @item.doi_state.awaiting_update?
    ezid_identifer = Ezid::Identifier.modify(@item.doi, doi_metadata)
    return if ezid_identifer.blank?

    if @item.private?
      @item.doi_state.unpublish!
    else
      @item.doi_state.synced!
    end
    ezid_identifer
    # EZID API call has failed so roll back to previous state change
  rescue StandardError => e
    # Skip the next handle_doi_states after_save callback and roll back
    # the state to it's previous value. By skipping the callback we can prevent
    # it temporarily from queueing another job. As this could make it end up
    # right back here again resulting in an infinite loop.
    @item.skip_handle_doi_states = true
    if @item.private?
      @item.doi_state.synced!
    else
      @item.unpublish!
    end
    raise e
  end

  def self.remove(doi)
    Ezid::Identifier.modify(doi, status: "#{Ezid::Status::UNAVAILABLE} | withdrawn", export: 'no')
  end

  private

  # Parse GenericFile and return hash of relevant DOI information
  def doi_metadata
    {
      datacite_creator:  @item.authors.join('; '),
      datacite_publisher: PUBLISHER,
      datacite_publicationyear: @item.sort_year.present? ? @item.sort_year : '(:unav)',
      datacite_resourcetype: DATACITE_METADATA_SCHEME[@item.item_type_with_status_code],
      datacite_title:  @item.title,
      target: Rails.application.routes.url_helpers.item_url(id: @item.id),
      # Can only set status if been minted previously, else its public
      status: @item.private? && @item.doi.present? ? UNAVAILABLE_MESSAGE : Ezid::Status::PUBLIC,
      export: @item.private? ? 'no' : 'yes'
    }
  end

end
