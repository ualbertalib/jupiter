class Items::FilesController < ApplicationController

  def create
    @draft_item = DraftItem.find(params[:item_id])
    authorize  @draft_item, :file_create?


    # We upload files one at a time from UI
    if params[:file].present?
      @draft_item.files.attach(params[:file])
    end

    @file = @draft_item.files.last

    # Return a json response of the partial `file.html.erb` so Dropzone can append the uploaded image to the dom
    if @file
      # Reuse existing partial
      file_partial = render_to_string(
        'items/draft/_file',
        layout: false,
        formats: [:html],
        locals: { file: @file }
      )

      render json: { file: file_partial }, status: 200
    else
      render json: @file.errors, status: 400
    end
  end

  def destroy
    @draft_item = DraftItem.find(params[:item_id])
    authorize  @draft_item, :file_destroy?

    @file = @draft_item.files.find(params[:id])

    @file.purge
  end
end
