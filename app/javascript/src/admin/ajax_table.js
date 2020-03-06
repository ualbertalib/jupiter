$(document).on('turbolinks:load', () => {
  function renderNewTable() {
    const $form = $(this).closest('form');
    let action = $form.attr('action');
    if (!action) {
      action = window.location.href;
    }
    $.get(action, $form.serialize(), null, 'script');
    return false;
  }

  function ajaxLink() {
    $.getScript(this.href);
    return false;
  }
  // Fetch new table for autocomplete and filter widgets
  $('.js-autocomplete select').change(renderNewTable);

  // TODO: Could be improved. Should maybe bring in a `debounce` function for this search
  $('.js-autocomplete input').keyup(renderNewTable);

  // Sorting and pagination links
  $('#js-ajax-table').on('click', ' th a.sort_link, .pagination a', ajaxLink);
});
