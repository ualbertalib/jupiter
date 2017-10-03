function init_autocomplete(selector, query_path, options) {
  // Setup the DOM element identified by selector to do autocomplete via typeahead,
  // grabbing data from query_path.

  // Options and defaults
  if (typeof options === "undefined") {
    options = {};
  }
  if (!('limit' in options)) { options.limit = 50; }
  if (!('display_key' in options)) { options.display_key = 'name'; }
  // See also 'selected' option below

  $(document).on('turbolinks:load', function() {
    var fetch_from_path = new Bloodhound({
      datumTokenizer: Bloodhound.tokenizers.whitespace,
      queryTokenizer: Bloodhound.tokenizers.whitespace,
      remote: {
        url: query_path + '?query=%QUERY',
        wildcard: '%QUERY'
      }
    });
    $(selector).typeahead({
      highlight: true,
      hint: false,
    },
    {
      source: fetch_from_path,
      display: options.display_key,
      limit: options.limit
    });
    // Handler for selected item in autocomplete list
    if ('selected' in options) {
      $(selector).bind('typeahead:selected', function(event, datum, name) {
        options.selected(datum);
      });
    }
    else {
      // If json has a 'url' attribute, go to the URL on select
      $(selector).bind('typeahead:selected', function(event, datum, name) {
        if ('url' in datum) {
          window.location = datum.url;
        }
      });
    }
  });
}
