$(document).on('turbolinks:load', function() {
  // Fetch new table for autocomplete and filter widgets
  $('.js-autocomplete select').change(function() {
    render_new_table($(this));
    return false;
  });

  // TODO: Could be improved. Should maybe bring in a `debounce` function for this search
  $('.js-autocomplete input').keyup(function() {
    render_new_table($(this));
    return false;
  });

  // Sorting and pagination links
  $('#js-ajax-table').on('click', ' th a.sort_link, .pagination a', function () {
    $.getScript(this.href);
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
