$(document).on('turbolinks:load', function() {
  // Fetch new table when clickin headers and pagination links
  $('.jupiter-autocomplete-results').on('click', 'thead a, a.page-link', function() {
    $.getScript(this.href);
    return false;
  });
  // Fetch new table for autocomplete widget
  $('.jupiter-autocomplete').on('keyup', function() {
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
