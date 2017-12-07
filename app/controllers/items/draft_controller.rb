class Items::DraftController < ApplicationController

  include Wicked::Wizard

  steps(*DraftItem.wizard_steps.keys)

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
