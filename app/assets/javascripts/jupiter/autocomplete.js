$(document).on('turbolinks:load', function() {
  // Fetch new table when clicking headers and pagination links
  $('.jupiter-autocomplete-results').on('click', 'thead a, a.page-link', function() {
    $.getScript(this.href);
    return false;
  });
  // Fetch new table for autocomplete and filter widgets
  $('.jupiter-autocomplete input,select').bind("change keyup input search", function() {
    render_new_table($(this));
    return false;
  })

  function render_new_table($changed_element) {
    var $form = $changed_element.closest('form');
    var action = $form.attr('action');
    if (!action) {
      action=window.location.href;
    }
    $.get(action, $form.serialize(), null, "script");
  }
});
