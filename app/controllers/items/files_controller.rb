class Items::FilesController < ApplicationController

  def create
    @draft_item = DraftItem.find(params[:item_id])
    # We upload files one at a time from UI
    if params[:draft_item][:files].present?
      @draft_item.files.attach(params[:draft_item][:files])
    end

    file = @draft_item.files.last

    # Return a json response of the partial `file.html.erb` so Dropzone can append the uploaded image to the dom
    if file
      # Reuse existing partial
      file_partial = render_to_string(
        'items/draft/_file',
        layout: false,
        formats: [:html],
        locals: { file: file }
      )

      return render json: { file: file_partial }, status: 200
    end
  end

  def destroy
    @draft_item = DraftItem.find(params[:item_id])
  end
end
