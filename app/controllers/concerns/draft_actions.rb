module DraftActions
  extend ActiveSupport::Concern

  included do
    before_action :initialize_communities, only: [:show]
    before_action :set_draft, only: [:show, :update, :destroy]
  end

  def show
    authorize @draft if authorize?

    @is_edit = @draft.uuid.present?
    @draft.sync_with_fedora(for_user: current_user) if @is_edit

    # Do not allow users to skip to uncompleted steps
    if @draft.uncompleted_step?(draft_class.wizard_steps, step)
      redirect_to wizard_path(@draft.last_completed_step, draft_id_param => @draft.id),
                  alert: t('.please_follow_the_steps')
    # Handles edge case of removing all files via ajax then attempting to directly view the review step
    elsif step == steps.last && @draft.files.empty?
      redirect_to wizard_path(:upload_files, draft_id_param => @draft.id),
                  alert: t('.files_are_required_to_continue')
    else
      render_wizard
    end
  end

  def update
    authorize @draft if authorize?

    params[draft_param] ||= {}

    # Only update the draft's step if it hasn't been completed yet
    if draft_class.wizard_steps[@draft.wizard_step] < draft_class.wizard_steps[step]
      params[draft_param][:wizard_step] = draft_class.wizard_steps[step]
    end

    case wizard_value(step)
    when describe_step_name
      params[draft_param][:status] = draft_class.statuses[:active]

      @draft.member_of_paths = { community_id: [], collection_id: [] }
      communities = params[draft_param].delete :community_id
      communities.each_with_index do |community_id, idx|
        next if community_id.blank?
        @draft.member_of_paths['community_id'] << community_id
        collection_id = params[draft_param]['collection_id'][idx]
        @draft.member_of_paths['collection_id'] << collection_id
      end
      params[draft_param].delete :collection_id

      # TODO: Handle required year but optional day/month better? Keep as string?
      # Set month/day to Jan 1st if left blank
      if params[draft_param][:date_created].blank?
        params[draft_param]['date_created(3i)'] = '1' if params[draft_param]['date_created(3i)'].blank?

        params[draft_param]['date_created(2i)'] = '1' if params[draft_param]['date_created(2i)'].blank?
      end

      @draft.update(permitted_attributes(draft_class))

      render_wizard @draft
    when review_step_name
      params[draft_param][:status] = draft_class.statuses[:archived]

      if @draft.update(permitted_attributes(draft_class))

        # TODO: Improve this? Is there a way to gracefully handle errors coming back from fedora?
        item = item_class.from_draft(@draft)

        # Redirect to the new item show page
        redirect_to item_path(item), notice: t('.successful_deposit')
      else
        # handle errors on draft valdiations
        render_wizard @draft
      end
    else
      params[draft_param][:status] = draft_class.statuses[:active]

      @draft.update(permitted_attributes(draft_class))
      render_wizard @draft
    end
  end

  def create
    create_params = { user: current_user }
    if params[:collection].present?
      collection = Collection.find(params[:collection])
      create_params['member_of_paths'] = {
        'community_id' => [collection.community_id],
        'collection_id' => [collection.id]
      }
    end
    @draft = draft_class.create(create_params)

    authorize @draft if authorize?

    redirect_to wizard_path(steps.first, draft_id_param => @draft.id)
  end

  def destroy
    authorize @draft if authorize?

    @draft.destroy

    redirect_back(fallback_location: root_path, notice: t('.successful_deletion'))
  end

  private

  def authorize?
    true
  end

  def draft_class
    DraftItem
  end

  def item_class
    Item
  end

  def describe_step_name
    :describe_item
  end

  def review_step_name
    :review_and_deposit_item
  end

  def draft_param
    :draft_item
  end

  def draft_id_param
    :item_id
  end

  def set_draft
    @draft = draft_class.find(params[draft_id_param])
  end

  def initialize_communities
    @communities = Community.all.sort(:title, :desc)
  end
end
