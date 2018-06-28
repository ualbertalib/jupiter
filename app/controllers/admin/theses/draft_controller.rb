class Admin::Theses::DraftController < Admin::AdminController

  include Wicked::Wizard

  before_action :initialize_communities, only: [:show]

  steps(*DraftThesis.wizard_steps.keys.map(&:to_sym))

  def show
    @draft_thesis = DraftThesis.find(params[:thesis_id])

    @is_edit = @draft_thesis.uuid.present?
    @draft_thesis.sync_with_fedora(for_user: current_user) if @is_edit

    # Do not allow users to skip to uncompleted steps
    if @draft_thesis.uncompleted_step?(DraftThesis.wizard_steps, step)
      redirect_to wizard_path(@draft_thesis.last_completed_step, thesis_id: @draft_thesis.id),
                  alert: t('.please_follow_the_steps')
    # Handles edge case of removing all files via ajax then attempting to directly view the review step
    elsif step == steps.last && @draft_thesis.files.empty?
      redirect_to wizard_path(:upload_files, thesis_id: @draft_thesis.id),
                  alert: t('.files_are_required_to_continue')
    else
      render_wizard
    end
  end

  def update
    @draft_thesis = DraftThesis.find(params[:thesis_id])

    params[:draft_thesis] ||= {}

    # Only update the draft_thesis's step if it hasn't been completed yet
    if DraftThesis.wizard_steps[@draft_thesis.wizard_step] < DraftThesis.wizard_steps[step]
      params[:draft_thesis][:wizard_step] = DraftThesis.wizard_steps[step]
    end

    case wizard_value(step)
    when :describe_thesis
      params[:draft_thesis][:status] = DraftThesis.statuses[:active]

      @draft_thesis.member_of_paths = { community_id: [], collection_id: [] }
      communities = params[:draft_thesis].delete :community_id
      communities.each_with_index do |community_id, idx|
        next if community_id.blank?
        @draft_thesis.member_of_paths['community_id'] << community_id
        collection_id = params[:draft_thesis]['collection_id'][idx]
        @draft_thesis.member_of_paths['collection_id'] << collection_id
      end
      params[:draft_thesis].delete :collection_id

      @draft_thesis.update(permitted_attributes(DraftThesis))

      render_wizard @draft_thesis
    when :review_and_deposit_thesis
      params[:draft_thesis][:status] = DraftThesis.statuses[:archived]

      if @draft_thesis.update(permitted_attributes(DraftThesis))

        # TODO: Improve this? Is there a way to gracefully handle errors coming back from fedora?
        thesis = Thesis.from_draft(@draft_thesis)

        # Redirect to the new thesis show page
        redirect_to item_path(thesis), notice: t('.successful_deposit')
      else
        # handle errors on draft_thesis valdiations
        render_wizard @draft_thesis
      end
    else
      params[:draft_thesis][:status] = DraftThesis.statuses[:active]

      @draft_thesis.update(permitted_attributes(DraftThesis))
      render_wizard @draft_thesis
    end
  end

  # Deposit link
  def create
    create_params = { user: current_user }
    if params[:collection].present?
      collection = Collection.find(params[:collection])
      create_params['member_of_paths'] = {
        'community_id' => [collection.community_id],
        'collection_id' => [collection.id]
      }
    end
    @draft_thesis = DraftThesis.create(create_params)

    redirect_to wizard_path(steps.first, thesis_id: @draft_thesis.id)
  end

  def destroy
    @draft_thesis = DraftThesis.find(params[:thesis_id])

    @draft_thesis.destroy

    redirect_back(fallback_location: root_path, notice: t('.successful_deletion'))
  end

  def initialize_communities
    @communities = Community.all.sort(:title, :desc)
  end

end
