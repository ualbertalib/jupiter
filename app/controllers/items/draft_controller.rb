class Items::DraftController < ApplicationController

  include Wicked::Wizard
  include DraftActions

  steps(*DraftItem.wizard_steps.keys.map(&:to_sym))

end
