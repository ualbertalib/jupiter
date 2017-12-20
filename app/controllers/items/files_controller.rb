class Items::FilesController < ApplicationController

  def create
    @draft_item = DraftItem.find(params[:item_id])
    authorize  @draft_item, :file_create?

    # We upload files one at a time from UI
    if params[:file].present?
      if @draft_item.files.attach(params[:file])
        file_partial = render_to_string(
          'items/draft/_files_list',
          layout: false,
          formats: [:html],
          object: @draft_item
        )

        render json: { files_list_html: file_partial }, status: 200
      else
        render json: @file.errors, status: 400
      end
    end
  end

  def destroy
    @draft_item = DraftItem.find(params[:item_id])
    authorize  @draft_item, :file_destroy?

    @file = @draft_item.files.find(params[:id])

    if @file.id == @draft_item.thumbnail_id
      @draft_item.update_attributes(thumbnail_id: nil)
    end

    @file.purge

    render :update_files_list
  end

  def set_thumbnail
    @draft_item = DraftItem.find(params[:item_id])
    authorize  @draft_item, :set_thumbnail?

    @draft_item.thumbnail_id = params[:id]
    @draft_item.save

    render :update_files_list
  end



end
