class DepositItemController < ApplicationController

  include Wicked::Wizard
  skip_after_action :verify_authorized

  steps :describe_item, :choose_license_and_visibility, :upload_files, :review_and_deposit_item

  def show
    case wizard_value(step)
    when :describe_item
      @draft_item = DraftItem.new(user: current_user)
      @communities = Community.all
    when 'wicked_finish'
      flash[:notice] = 'Success!'
    else
      @draft_item = DraftItem.find(params[:draft_item_id])
    end

    authorize @draft_item
    render_wizard
  end

  def update
    # @draft_item = Item.find(params[:item_id])
    # authorize @draft_item
    # @draft_item.update_attributes(params[:item])
    # render_wizard @draft_item
    redirect_to next_wizard_path
  end

  def create
    puts params[:draft_item]
    # TODO: Need to create the object before getting to the wizard... how to do this?
    # Could be a nested route... item_deposit and item_deposit/:item_id/build where build is the actual wizard
    # So first form of the wizard isnt actually part of the wizard,
    # then preceeding forms are the actual wizard if this makes sense
    @draft_item = DraftItem.new(permitted_attributes(DraftItem))
    @draft_item.user = current_user
    authorize @draft_item

    redirect_to wizard_path(steps.second) # , :item_id => @draft_item.id)
  end

end
