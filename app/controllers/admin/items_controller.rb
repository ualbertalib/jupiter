class Admin::ItemsController < Admin::AdminController

  def index
    # no restrictions on items searched for
    search_query_index = UserSearchService.new(params: params, current_user: current_user)
    @results = search_query_index.results
    @search_models = search_query_index.search_models
  end

  def destroy
    @item = begin
      Item.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      Thesis.find(params[:id])
    end

    begin
      # rubocop:disable Rails/SkipsModelValidations
      # HACK: bit of a silly hack (write a nil directly to the column) to get around this hack where destroying
      # the item tries to destroy the attachments, which then errors out because the attachment id is
      # still referenced by the item that's about to be destroyed.
      #
      # TODO: investigate further why this happens (seems inconsistent with the settings for
      # the constraint:
      #  +add_foreign_key "items", "active_storage_attachments", column: "logo_id", on_delete: :nullify+
      # which should allow this to work?) and consider dropping the constraint
      # entirely if this is unreliable on PostgreSQL

      @item.update_columns(logo_id: nil)

      # rubocop:enable Rails/SkipsModelValidations
      @item.destroy!
      flash[:notice] = t('.deleted')
    rescue StandardError => e
      flash[:alert] = t('.failed')
      Rollbar.error("Error deleting #{@item.id}", e)
    end

    redirect_back(fallback_location: root_path)
  end

end
