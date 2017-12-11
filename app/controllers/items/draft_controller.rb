class Items::DraftController < ApplicationController

  include Wicked::Wizard

  steps(*DraftItem.wizard_steps.keys.map(&:to_sym))

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
    params[:draft_item] ||= {}
    params[:draft_item][:wizard_step] = DraftItem.wizard_steps[step]
    params[:draft_item][:status] = DraftItem.statuses[:active]

    case wizard_value(step)
    when :describe_item

      community = params[:draft_item].delete :community_id
      collection = params[:draft_item].delete :collection_id

      # TODO: save tags, and do a bunch of has_many magic with creating tags on the fly
    when :upload_files
      # ActiveStorage broken (or is it dropzone)? Need to loop through all files and save them individually
      # Shouldn't have to do this
      if params[:draft_item][:files].present?
        params[:draft_item][:files].each do |file|
          @draft_item.files.attach(params[:draft_item][:files][file])
        end
      end
    when :review_and_deposit_item
      params[:draft_item][:status] = DraftItem.statuses[:archived]
    end

    # @draft_item.update_attributes(permitted_attributes(DraftItem))

    render_wizard @draft_item
  end

  # Deposit link
  def create
    @draft_item = DraftItem.create(user: current_user)
    authorize @draft_item

    redirect_to wizard_path(steps.first, item_id: @draft_item.id)
  end

end
