class DepositItemController < ApplicationController

  include Wicked::Wizard
  skip_after_action :verify_authorized

  steps :describe_item, :choose_license_and_visibility, :upload_files, :review_and_deposit_item

  def show
    #@item = Item.find(params[:item_id])
    #authorize @item
    render_wizard
  end

  def update
    #@item = Item.find(params[:item_id])
    #authorize @item
    #@item.update_attributes(params[:item])
    render_wizard #@item
  end

  def create
    # @item = Item.create
    # authorize @item
    redirect_to wizard_path(steps.first) #, item_id: item.id)
  end

end
