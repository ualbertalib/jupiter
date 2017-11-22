$(document).on('turbolinks:load', function() {
  $('.js-communities-collections-searchbox').each(function() {
    $(this).select2({
      theme: 'bootstrap',
      ajax: {
        // The '.json' fixes issues with chrome cacheing
        url: 'communities.json',
        allowClear: true,
        dataType: 'json',
        data: function(params) {
          var query = {
            query: params.term
          };
          return query;
        }
      }
    }).on('select2:select', function(e) {
      var data = e.params.data;
      if (data.path) {
        // To ensure we get the placeholder when user clicks back (firefox)
        $(this).val('');
        window.location.href = data.path;
      }
    });
  });
});
