module DepositItemHelper
  def progress_bar_step_class(wizard_step)
    # TODO: If future steps have already been completed,
    # I should be able to still click ahead to them
    # But if they haven't been completed then they should be disabled
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
    t('items.draft.progress_bar_text', step_index: step_index(step), total_steps: wizard_steps.size)
  end

  def step_index(wizard_step)
    (wizard_steps.index(wizard_step) + 1)
  end
end
