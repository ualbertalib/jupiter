$(document).on('turbolinks:load', function() {
  $('.jupiter-autocomplete').each(function() {
    var query_path = $(this).data('query-path');
    var display_key = $(this).data('display-key');
    var limit = $(this).data('query-limit');
    // 'selected' defines what to do when clicking selected item (default: visit url if present in returned data)
    var selected = $(this).data('selected-action');

    if (!limit) {
      limit = 50;
    }
    if (!display_key) {
      display_key = 'name';
    }

    var fetch_from_path = new Bloodhound({
      datumTokenizer: Bloodhound.tokenizers.whitespace,
      queryTokenizer: Bloodhound.tokenizers.whitespace,
      remote: {
        url: query_path + '?query=%QUERY',
        wildcard: '%QUERY'
      }
    });
    $(this).typeahead({
      highlight: true,
      hint: false,
    },
    {
      source: fetch_from_path,
      display: display_key,
      limit: limit
    });
    // Handler for selected item in autocomplete list
    if (selected) {
      $(this).bind('typeahead:selected', function(event, datum, name) {
        selected(datum);
      });
    }
    else {
      // If json has a 'url' attribute, go to the URL on select
      $(this).bind('typeahead:selected', function(event, datum, name) {
        if ('url' in datum) {
          window.location = datum.url;
        }
      });
    }
  });
});
