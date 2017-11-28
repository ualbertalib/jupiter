class DepositItemController < ApplicationController

  include Wicked::Wizard
  skip_after_action :verify_authorized

  steps :describe_item, :choose_license_and_visibility, :upload_files, :review_and_deposit_item

  def show
    case wizard_value(step)
    when :describe_item
      # @item = ItemDraft.new_locked_ldp_object
      @languages = languages
      @item_types = item_types
      @communities = Community.all
    when 'wicked_finish'
      flash[:notice] = 'Success!'
      # else
      #   @item = Item.find(params[:item_id])
    end
    # authorize @item
    render_wizard
  end

  def update
    # @item = Item.find(params[:item_id])
    # authorize @item
    # @item.update_attributes(params[:item])
    # render_wizard @item
    redirect_to next_wizard_path
  end

  def create
    # TODO: Need to create the object before getting to the wizard... how to do this?
    # Could be a nested route... item_deposit and item_deposit/:item_id/build where build is the actual wizard
    # So first form of the wizard isnt actually part of the wizard,
    # then preceeding forms are the actual wizard if this makes sense

    # @item = ItemDraft.create(permitted_attributes(Item))
    # authorize @item
    redirect_to wizard_path(steps.second) # , :item_id => @item.id)
  end

  private

  def item_types
    {
      'Book' => :book,
      'Book Chapter' => :book_chapter,
      'Conference\/workshop Poster' => :conference_workshop_poster,
      'Conference\/workshop Presentation' => :conference_workshop_presenation,
      'Dataset' => :dataset,
      'Image' => :image,
      'Journal Article (Draft-Submitted)' => :journal_article_draft,
      'Journal Article (Published)' => :journal_article_published,
      'Learning Object' => :learning_object,
      'Report' => :report,
      'Research Material' => :research_material,
      'Review' => :review
    }
  end

  def languages
    {
      'English' => :english,
      'French' => :french,
      'Spanish' => :spanish,
      'Chinese' => :chinese,
      'German' => :german,
      'Italian' => :italian,
      'Russian' => :russian,
      'Ukrainian' => :ukrainian,
      'Japanese' => :japanese,
      'No linguistic content' => :no_linguistic_content,
      'Other' => :other
    }
  end

end
