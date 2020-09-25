class Admin::DoiableController < Admin::AdminController

  def reset_doi
    item = begin
      Item.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      Thesis.find(params[:id])
    end

    item.handle_doi_states
    redirect_back(fallback_location: :root)
  end

end
