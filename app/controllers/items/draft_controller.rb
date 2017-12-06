class Items::DraftController < ApplicationController

  include Wicked::Wizard

  binding.pry

  # TODO: Should be able to use DraftItem.wizard_steps.keys instead of duplicating this,
  #  but wicked not having any of it
  steps :describe_item, :choose_license_and_visibility, :upload_files, :review_and_deposit_item

  def show
    @draft_item = DraftItem.find(params[:item_id])
    authorize @draft_item

    case wizard_value(step)
    when :describe_item
      @communities = Community.all
    when 'wicked_finish'
      flash[:notice] = 'Success!'
    end

    render_wizard
  end

  def update
    @draft_item = DraftItem.find(params[:item_id])
    authorize @draft_item

    params[:draft_item][:wizard_step] = step
    params[:draft_item][:status] = DraftItem.status[:active]
    params[:draft_item][:status] = DraftItem.status[:archived] if step == steps.last

    @draft_item.update_attributes(permitted_attributes(DraftItem))
    render_wizard @draft_item
  end

  # Deposit link
  def create
    @draft_item = DraftItem.create(user: current_user)
    authorize @draft_item

    redirect_to wizard_path(steps.first, item_id: @draft_item.id)
  end

end
