class Admin::Theses::FilesController < Admin::AdminController

  def create
    @draft_thesis = DraftThesis.find(params[:thesis_id])

    if @draft_thesis.files.attach(params[:file])
      file_partial = render_to_string(
        'admin/theses/draft/_files_list',
        layout: false,
        formats: [:html]
      )

      render json: { files_list_html: file_partial }, status: :ok
    else
      render json: @draft_thesis.errors, status: :bad_request
    end
  end

  def destroy
    @draft_thesis = DraftThesis.find(params[:thesis_id])

    @draft_thesis.files.find(params[:id]).purge

    render :update_files_list
  end

  def set_thumbnail
    @draft_thesis = DraftThesis.find(params[:thesis_id])

    @draft_thesis.thumbnail_id = params[:id]

    if @draft_thesis.save
      render :update_files_list
    else
      render json: @draft_thesis.errors, status: :bad_request
    end
  end

end
