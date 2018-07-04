module DraftFilesActions
  extend ActiveSupport::Concern

  included do
    before_action :set_draft, only: [:create, :destroy, :set_thumbnail]
  end

  def create
    authorize @draft, :file_create? if authorize?

    if @draft.files.attach(params[:file])
      file_partial = render_to_string(
        file_partial_location,
        layout: false,
        formats: [:html]
      )

      render json: { files_list_html: file_partial }, status: :ok
    else
      render json: @draft.errors, status: :bad_request
    end
  end

  def destroy
    authorize @draft, :file_destroy? if authorize?

    @draft.files.find(params[:id]).purge

    render :update_files_list
  end

  def set_thumbnail
    authorize @draft, :set_thumbnail? if authorize?

    @draft.thumbnail_id = params[:id]

    if @draft.save
      render :update_files_list
    else
      render json: @draft.errors, status: :bad_request
    end
  end

  private

  def authorize?
    true
  end

  def set_draft
    # TODO: reason why we assign to @draft_item is because we haven't switched views over yet
    @draft = @draft_item = DraftItem.find(params[:item_id])
  end

  def file_partial_location
    'items/draft/_files_list'
  end
end
