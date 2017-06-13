class WorksController < ApplicationController

  before_action :load_work, only: [:show, :edit, :update]

  def new
    @work = Work.new
  end

  def create
    communities = params[:work].delete :community
    collections = params[:work].delete :collection

    @work = Work.new(work_params)

    communities.each_with_index do |community, idx|
      @work.add_to_path(community, collections[idx])
    end

    # see also https://github.com/samvera/hydra-works/wiki/Lesson%3A-Add-attached-files
    params[:work][:file].each do |file|
      fileset = FileSet.new
      Hydra::Works::AddFileToFileSet.call(fileset, file, :original_file, update_existing: false, versioning: false)
      fileset.save!
      # pull in hydra derivatives, set temp file base
      # Hydra::Works::CharacterizationService.run(fileset.characterization_proxy, filename)
      @work.members << fileset
    end

    @work.save!
    redirect_to @work
  end

  def update
    @work.update!(work_params)
    redirect_to @work
  end

  private

  def load_work
    @work = Work.find(params[:id])
  end

  def work_params
    params[:work].permit(Work.property_names)
  end
end
