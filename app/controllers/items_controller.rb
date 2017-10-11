class ItemsController < ApplicationController

  before_action :load_item, only: [:show, :edit, :update]

  def new
    @item = Item.new_locked_ldp_object
    authorize @item
  end

  def create
    communities = params[:item].delete :community
    collections = params[:item].delete :collection

    @item = Item.new_locked_ldp_object(permitted_attributes(Item))
    authorize @item

    # TODO: add validations?
    @item.unlock_and_fetch_ldp_object do |unlocked_item|
      unlocked_item.owner = current_user.id

      communities.each_with_index do |community, idx|
        # TODO: raises undefined method `[]' for nil:NilClass on empty form
        unlocked_item.add_to_path(community, collections[idx])
      end

      # see also https://github.com/samvera/hydra-works/wiki/Lesson%3A-Add-attached-files
      params[:item][:file].each do |file|
        fileset = FileSet.new
        Hydra::Works::AddFileToFileSet.call(fileset, file, :original_file, update_existing: false, versioning: false)
        fileset.save!
        # pull in hydra derivatives, set temp file base
        # Hydra::Works::CharacterizationService.run(fileset.characterization_proxy, filename)
        unlocked_item.members << fileset
      end

      unlocked_item.save!
    end
    redirect_to @item
  end

  def update
    authorize @item
    @item.unlock_and_fetch_ldp_object do |unlocked_item|
      unlocked_item.update!(permitted_attributes(@item))
    end
    redirect_to @item
  end

  private

  def load_item
    @item = Item.find(params[:id])
    authorize @item
  end

end
