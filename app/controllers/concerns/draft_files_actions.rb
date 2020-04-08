module DraftFilesActions
  extend ActiveSupport::Concern

  included do
    before_action :set_draft, only: [:create, :destroy, :set_thumbnail]
  end

  def create
    authorize @draft, :file_create? if needs_authorization?

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
    authorize @draft, :file_destroy? if needs_authorization?

    @draft.files.find(params[:id]).purge

    render :update_files_list
  end

  def set_thumbnail
    authorize @draft, :set_thumbnail? if needs_authorization?

    @draft.thumbnail_id = @draft.files.find_by(id: params[:id]).blob_id
    if @draft.save
      render :update_files_list
    else
      render json: @draft.errors, status: :bad_request
    end
  end

  private

  # Draft items will need authorization checks in place. But since draft theses are inherited
  # from the admin controller, they already have authorization checks in place so we need a way
  # to opt out of authorization checks for all the controller actions above
  def needs_authorization?
    true
  end

  def draft_class
    DraftItem
  end

  def item_class
    Item
  end

  def draft_id_param
    "#{item_class.model_name.singular}_id".to_sym
  end

  def set_draft
    @draft = draft_class.find(params[draft_id_param])
  end

  def file_partial_location
    'items/draft/_files_list'
  end
end
