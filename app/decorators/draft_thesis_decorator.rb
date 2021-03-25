class DraftThesisDecorator < ApplicationDecorator

  delegate_all

  def preview_description
    markdown(model.description)
  end

end
