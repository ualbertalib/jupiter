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
    ((step_index(step).to_f / wizard_steps.size) * 100).to_i
  end

  def progress_bar_text
    "#{step_index(step)} / #{wizard_steps.size}"
  end

  def step_index(wizard_step)
    (wizard_steps.index(wizard_step) + 1)
  end
end
