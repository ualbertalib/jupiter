SimpleForm.setup do |config|
  config.error_notification_class = 'alert alert-danger'
  config.button_class = 'btn btn-primary'
  config.boolean_label_class = nil

  config.wrappers :vertical_form, tag: 'div', class: 'form-group' do |b|
    b.use :html5
    b.use :placeholder
    b.optional :maxlength
    b.optional :minlength
    b.optional :pattern
    b.optional :min_max
    b.optional :readonly

    b.use :label, class: 'col-form-label' do
    end
    b.use :input, class: 'form-control'
    b.use :error, wrap_with: { tag: 'span', class: 'invalid-feedback' }
    b.use :hint, wrap_with: { tag: 'small', class: 'form-text text-muted' }
  end

  config.wrappers :vertical_file_input, tag: 'div', class: 'form-group' do |b|
    b.use :html5
    b.use :placeholder
    b.optional :maxlength
    b.optional :minlength
    b.optional :readonly

    b.use :label, class: 'col-form-label'
    b.use :input
    b.use :error, wrap_with: { tag: 'span', class: 'invalid-feedback' }
    b.use :hint, wrap_with: { tag: 'p', class: 'form-text text-muted' }
  end

  config.wrappers :vertical_boolean, tag: 'div', class: 'form-group' do |b|
    b.use :html5
    b.optional :readonly

    b.wrapper tag: 'div', class: 'form-check' do |ba|
      ba.use :label_input
    end

    b.use :error, wrap_with: { tag: 'span', class: 'invalid-feedback' }
    b.use :hint, wrap_with: { tag: 'p', class: 'form-text text-muted' }
  end

  config.wrappers :vertical_radio_and_checkboxes, tag: 'div', class: 'form-group' do |b|
    b.use :html5
    b.optional :readonly

    b.use :label, class: 'col-form-label'
    b.use :input
    b.use :error, wrap_with: { tag: 'span', class: 'invalid-feedback' }
    b.use :hint, wrap_with: { tag: 'p', class: 'form-text text-muted' }
  end

  config.wrappers :horizontal_form, tag: 'div', class: 'form-group row' do |b|
    b.use :html5
    b.use :placeholder
    b.optional :maxlength
    b.optional :minlength
    b.optional :pattern
    b.optional :min_max
    b.optional :readonly

    b.use :label, class: 'col-md-3 col-form-label'
    b.wrapper tag: 'div', class: 'col-md-9' do |ba|
      ba.use :input, class: 'form-control'
      ba.use :error, wrap_with: { tag: 'span', class: 'invalid-feedback' }
      ba.use :hint, wrap_with: { tag: 'p', class: 'form-text text-muted' }
    end
  end

  config.wrappers :horizontal_file_input, tag: 'div', class: 'form-group row' do |b|
    b.use :html5
    b.use :placeholder
    b.optional :maxlength
    b.optional :minlength
    b.optional :readonly
    b.use :label, class: 'col-md-3 col-form-label'

    b.wrapper tag: 'div', class: 'col-md-9' do |ba|
      ba.use :input
      ba.use :error, wrap_with: { tag: 'span', class: 'invalid-feedback' }
      ba.use :hint, wrap_with: { tag: 'p', class: 'form-text text-muted' }
    end
  end

  config.wrappers :horizontal_boolean, tag: 'div', class: 'form-group row' do |b|
    b.use :html5
    b.optional :readonly

    b.wrapper tag: 'div', class: 'offset-md-3 col-md-9' do |wr|
      wr.wrapper tag: 'div', class: 'form-check' do |ba|
        ba.use :label_input
      end

      wr.use :error, wrap_with: { tag: 'span', class: 'invalid-feedback' }
      wr.use :hint, wrap_with: { tag: 'p', class: 'form-text text-muted' }
    end
  end

  config.wrappers :horizontal_radio_and_checkboxes, tag: 'div', class: 'form-group row' do |b|
    b.use :html5
    b.optional :readonly

    b.use :label, class: 'col-md-3 col-form-label'
    b.wrapper tag: 'div', class: 'col-md-9' do |ba|
      ba.use :input
      ba.use :error, wrap_with: { tag: 'span', class: 'invalid-feedback' }
      ba.use :hint, wrap_with: { tag: 'p', class: 'form-text text-muted' }
    end
  end

  config.wrappers :inline_form, tag: 'div', class: 'form-group' do |b|
    b.use :html5
    b.use :placeholder
    b.optional :maxlength
    b.optional :minlength
    b.optional :pattern
    b.optional :min_max
    b.optional :readonly

    b.use :label, class: 'sr-only'
    b.use :input, class: 'form-control'
    b.use :error, wrap_with: { tag: 'span', class: 'invalid-feedback' }
    b.use :hint, wrap_with: { tag: 'p', class: 'form-text text-muted' }
  end

  config.wrappers :multi_select, tag: 'div', class: 'form-group' do |b|
    b.use :html5
    b.optional :readonly

    b.use :label, class: 'col-form-label'
    b.wrapper tag: 'div', class: 'form-inline' do |ba|
      ba.use :input, class: 'form-control'
      ba.use :error, wrap_with: { tag: 'span', class: 'invalid-feedback' }
      ba.use :hint, wrap_with: { tag: 'p', class: 'form-text text-muted' }
    end
  end

  config.default_wrapper = :vertical_form
  config.wrapper_mappings = {
    check_boxes: :vertical_radio_and_checkboxes,
    radio_buttons: :vertical_radio_and_checkboxes,
    file: :vertical_file_input,
    boolean: :vertical_boolean,
    datetime: :multi_select,
    date: :multi_select,
    time: :multi_select
  }
end

SimpleForm::Inputs::Base.class_eval do
  # Original method: https://github.com/plataformatec/simple_form/blob/master/lib/simple_form/inputs/base.rb#L191-L206
  # Need to monkey patch input field so we can add the `is-invalid` class on errors
  def merge_wrapper_options(options, wrapper_options)
    if wrapper_options
      wrapper_options.merge(options) do |key, oldval, newval|
        case key.to_s
        when 'class'
          classes = Array(oldval) + Array(newval)
          classes << 'is-invalid' if has_errors?
          classes
        when 'data', 'aria'
          oldval.merge(newval)
        else
          newval
        end
      end
    else
      options
    end
  end
end
