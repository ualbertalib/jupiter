class WorksController < ApplicationController

  before_action :load_work, only: [:show, :edit, :update]

  def new
    @work = Work.new_locked_ldp_object
  end

  def create
    communities = params[:work].delete :community
    collections = params[:work].delete :collection

    @work = Work.new_locked_ldp_object(work_params).unlock_and_fetch_ldp_object do |unlocked_work|
      communities.each_with_index do |community, idx|
        unlocked_work.add_to_path(community, collections[idx])
      end

      # see also https://github.com/samvera/hydra-works/wiki/Lesson%3A-Add-attached-files
      params[:work][:file].each do |file|
        fileset = FileSet.new
        Hydra::Works::AddFileToFileSet.call(fileset, file, :original_file, update_existing: false, versioning: false)
        fileset.save!
        # pull in hydra derivatives, set temp file base
        # Hydra::Works::CharacterizationService.run(fileset.characterization_proxy, filename)
        unlocked_work.members << fileset
      end

      unlocked_work.save!
    end
    redirect_to @work
  end

  def update
    @work.unlock_and_fetch_ldp_object do |unlocked_work|
      unlocked_work.update!(work_params)
    end
    redirect_to @work
  end

  def search
    @results = Work.search(q: params[:q])
  end

  private

  def load_work
    @work = Work.find(params[:id])
  end

  def work_params
    params[:work].permit(Work.safe_attributes)
  end

end
