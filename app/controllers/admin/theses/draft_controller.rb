class Admin::Theses::DraftController < Admin::AdminController

  include Wicked::Wizard
  include DraftActions

  steps(*DraftThesis.wizard_steps.keys.map(&:to_sym))

  private

  def authorize?
    false
  end

  def draft_class
    DraftThesis
  end

  def item_class
    Thesis
  end

  def describe_step_name
    :describe_thesis
  end

  def review_step_name
    :review_and_deposit_thesis
  end

  def draft_param
    :draft_thesis
  end

  def draft_id_param
    :thesis_id
  end

  def set_draft
    @draft = DraftThesis.find(params[:thesis_id])
  end

end
