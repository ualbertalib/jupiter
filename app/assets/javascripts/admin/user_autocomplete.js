$(document).on('turbolinks:load', function() {
  // Fetch new table for autocomplete and filter widgets
  $('.js-user-autocomplete select').change(function() {
    render_new_table($(this));
    return false;
  });

  // TODO: Could be improved. Should maybe bring in a `debounce` function for this search
  $('.js-user-autocomplete input').keyup(function() {
    render_new_table($(this));
    return false;
  });


  function render_new_table($changed_element) {
    var $form = $changed_element.closest('form');
    var action = $form.attr('action');
    if (!action) {
      action=window.location.href;
    }
    $.get(action, $form.serialize(), null, "script");
  }
});
