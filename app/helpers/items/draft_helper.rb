module Items::DraftHelper
  def progress_bar_step_class(wizard_step, draft)
    if draft.uncompleted_step?(draft.class.wizard_steps, wizard_step)
      'disabled'
    elsif wizard_step == step
      'active'
    else
      'visted'
    end
  end

  def header
    if @draft.is_a? DraftItem
      @is_edit ? t('items.draft.header_edit') : t('items.draft.header')
    else
      @is_edit ? t('admin.theses.draft.header_edit') : t('admin.theses.draft.header')
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

  def license_accordions
    { most_commonly_used: [:attribution_non_commercial],
      other_creative_commons_licenses: [
        :attribution,
        :attribution_non_commercial_no_derivatives,
        :attribution_non_commercial_share_alike,
        :attribution_no_derivatives,
        :attribution_share_alike,
        :cco_universal
      ],
      public_domain: [:public_domain_mark],
      link_to_another_license: [:license_text] }
  end

  def license_accordion_open?(accordion, license, truthy_value = 'true', falsey_value = 'false')
    if license_accordions[accordion].include?(license.to_sym)
      truthy_value
    else
      falsey_value
    end
  end
end
