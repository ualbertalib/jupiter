class Admin::Theses::DraftController < Admin::AdminController

  include Wicked::Wizard
  include DraftActions

  steps(*DraftThesis.wizard_steps.keys.map(&:to_sym))

  private

  def needs_authorization?
    false
  end

  def draft_class
    DraftThesis
  end

  def item_class
    Thesis
  end

end
