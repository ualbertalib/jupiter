class Items::DraftController < ApplicationController

  include Wicked::Wizard

  before_action :initialize_communities, only: [:show, :edit]

  steps(*DraftItem.wizard_steps.keys.map(&:to_sym))

  def show
    @draft_item = DraftItem.find(params[:item_id])
    authorize @draft_item

    @draft_item.sync_with_fedora if @draft_item.uuid.present?
    @is_edit = @draft_item.uuid.present?

    # Do not allow users to skip to uncompleted steps
    if @draft_item.uncompleted_step?(step)
      redirect_to wizard_path(@draft_item.last_completed_step, item_id: @draft_item.id),
                  alert: t('.please_follow_the_steps')
    # Handles edge case of removing all files via ajax then attempting to directly view the review step
    elsif step == steps.last && @draft_item.files.empty?
      redirect_to wizard_path(:upload_files, item_id: @draft_item.id),
                  alert: t('.files_are_required_to_continue')
    else
      render_wizard
    end
  end

  def update
    @draft_item = DraftItem.find(params[:item_id])
    authorize @draft_item

    params[:draft_item] ||= {}

    # Only update the draft_item's step if it hasn't been completed yet
    if DraftItem.wizard_steps[@draft_item.wizard_step] < DraftItem.wizard_steps[step]
      params[:draft_item][:wizard_step] = DraftItem.wizard_steps[step]
    end

    case wizard_value(step)
    when :describe_item
      params[:draft_item][:status] = DraftItem.statuses[:active]

      @draft_item.member_of_paths = { community_id: [], collection_id: [] }
      communities = params[:draft_item].delete :community_id
      communities.each_with_index do |community_id, idx|
        next if community_id.blank?
        @draft_item.member_of_paths['community_id'] << community_id
        collection_id = params[:draft_item]['collection_id'][idx]
        @draft_item.member_of_paths['collection_id'] << collection_id
      end
      params[:draft_item].delete :collection_id

      @draft_item.update_attributes(permitted_attributes(DraftItem))

      render_wizard @draft_item
    when :review_and_deposit_item
      params[:draft_item][:status] = DraftItem.statuses[:archived]

      if @draft_item.update_attributes(permitted_attributes(DraftItem))

        # TODO: Improve this? Is there a way to gracefully handle errors coming back from fedora?
        item = Item.from_draft(@draft_item)

        # Redirect to the new item show page
        redirect_to item_path(item), notice: t('.successful_deposit')
      else
        # handle errors on draft_item valdiations
        render_wizard @draft_item
      end
    else
      params[:draft_item][:status] = DraftItem.statuses[:active]

      @draft_item.update_attributes(permitted_attributes(DraftItem))
      render_wizard @draft_item
    end
  end

  # Deposit link
  def create
    @draft_item = DraftItem.create(user: current_user)
    authorize @draft_item

    redirect_to wizard_path(steps.first, item_id: @draft_item.id)
  end

  def destroy
    @draft_item = DraftItem.find(params[:item_id])
    authorize @draft_item

    @draft_item.destroy

    redirect_back(fallback_location: root_path, notice: t('.successful_deletion'))
  end

  def initialize_communities
    @communities = Community.all
  end

end
