module DepositItemHelper
  def progress_bar_step_class(wizard_step)
    if wizard_step == step
      'active'
    elsif past_step?(wizard_step)
      'visted'
    else
      'disabled'
    end
  end

  def progress_bar_percentage
    index = (wizard_steps.index(step) + 1)
    ((index.to_f / wizard_steps.size) * 100).to_i
  end
end
