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
      unlocked_work.add_communities_and_collections(communities, collections)
      unlocked_work.add_files(params)
      unlocked_work.save!
    end
    redirect_to @work
  end

  def update
    communities = params[:work].delete :community
    collections = params[:work].delete :collection

    authorize @work
    @work.unlock_and_fetch_ldp_object do |unlocked_work|
      unlocked_work.update_attributes(permitted_attributes(@work))
      unlocked_work.add_communities_and_collections(communities, collections)
      unlocked_work.add_files(params)
      unlocked_work.save!
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
