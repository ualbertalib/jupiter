class WorksController < ApplicationController

  before_action :load_work, only: [:show, :edit, :update]

  def new
    @work = Work.new_locked_ldp_object
    authorize @work
  end

  def create
    communities = params[:work].delete :community
    collections = params[:work].delete :collection

    @work = Work.new_locked_ldp_object(permitted_attributes(Work))
    authorize @work

    # TODO: add validations?
    @work.unlock_and_fetch_ldp_object do |unlocked_work|
      unlocked_work.owner = current_user.id

      communities.each_with_index do |community, idx|
        # TODO: raises undefined method `[]' for nil:NilClass on empty form
        unlocked_work.add_to_path(community, collections[idx])
      end

      # TODO: move this so that update can use it too (model?)
      # Need a work id for file sets to point to
      unlocked_work.save! if params[:work][:file].any?

      # see also https://github.com/samvera/hydra-works/wiki/Lesson%3A-Add-attached-files
      params[:work][:file].each do |file|
        fileset = FileSet.new_locked_ldp_object
        fileset.unlock_and_fetch_ldp_object do |unlocked_fileset|
          unlocked_fileset.owner = unlocked_work.owner
          unlocked_fileset.visibility = unlocked_work.visibility
          Hydra::Works::AddFileToFileSet.call(unlocked_fileset, file, :original_file,
                                              update_existing: false, versioning: false)
          unlocked_fileset.is_member_of = unlocked_work.id
          unlocked_fileset.save!
          unlocked_work.members << unlocked_fileset
        end
        # pull in hydra derivatives, set temp file base
        # Hydra::Works::CharacterizationService.run(fileset.characterization_proxy, filename)
      end

      unlocked_work.save!
    end
    redirect_to @work
  end

  def update
    authorize @work
    @work.unlock_and_fetch_ldp_object do |unlocked_work|
      unlocked_work.update!(permitted_attributes(@work))
    end
    redirect_to @work
  end

  def search
    @results = Work.search(q: params[:q])
    authorize @results, :index?
  end

  private

  def load_work
    @work = Work.find(params[:id])
    authorize @work
  end

end
