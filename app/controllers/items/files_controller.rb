class Items::FilesController < ApplicationController

  def create
    @draft_item = DraftItem.find(params[:item_id])
    authorize @draft_item, :file_create?

    if @draft_item.files.attach(params[:file])
      file_partial = render_to_string(
        'items/draft/_files_list',
        layout: false,
        formats: [:html]
      )

      render json: { files_list_html: file_partial }, status: :ok
    else
      render json: @draft_item.errors, status: :bad_request
    end
  end

  def destroy
    @draft_item = DraftItem.find(params[:item_id])
    authorize @draft_item, :file_destroy?

    @draft_item.files.find(params[:id]).purge

    render :update_files_list
  end

  def set_thumbnail
    @draft_item = DraftItem.find(params[:item_id])
    authorize @draft_item, :set_thumbnail?

    @draft_item.thumbnail_id = params[:id]

    if @draft_item.save
      render :update_files_list
    else
      render json: @draft_item.errors, status: :bad_request
    end
  end

end
