module Items::DraftHelper
  def progress_bar_step_class(wizard_step)
    if @draft_item.uncompleted_step?(wizard_step)
      'disabled'
    elsif wizard_step == step
      'active'
    else
      'visted'
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

  def license_accordion_open?(accordion, license, truthy_value = 'true', falsey_value = 'false')
    license_accordions = { most_commonly_used: [:attribution_non_commercial],
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

    if license_accordions[accordion].include?(license.to_sym)
      truthy_value
    else
      falsey_value
    end
  end

  # Probably easier way of doing this?
  def file_icon(content_type)
    case content_type
    when /^image/
      'file-image-o'
    when /^audio/
      'file-audio-o'
    when /^video/
      'file-video-o'
    when /^text/
      'file-text-o'
    when /pdf/
      'file-pdf-o'
    when /zip/
      'file-archive-o'
    when /(excel|sheet)/
      'file-excel-o'
    when /(powerpoint|presentation)/
      'file-powerpoint-o'
    when /word/
      'file-word-o'
    else
      'file-o'
    end
  end

  # TODO: Remove this after upgrading activestorage
  # Returns true if the content_type of this blob is in the image range, like image/png.
  # https://github.com/rails/rails/blob/7b1dfac29146ddda82d1ee226cdb8ef281013502/activestorage/app/models/active_storage/blob.rb#L95
  def image?(file_attachment)
    file_attachment.content_type.start_with?('image')
  end
end
