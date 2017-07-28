class WorksController < ApplicationController

  # TODO: Show/edit/etc pages?
  before_action :load_work, only: [:update]

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
      communities.each_with_index do |community, idx|
        # TODO: raises undefined method `[]' for nil:NilClass on empty form
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
  end

end
