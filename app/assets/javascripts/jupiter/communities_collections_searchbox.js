$(document).on('turbolinks:load', function() {
  $('.js-communities-collections-searchbox').select2({
    theme: 'bootstrap',
    ajax: {
      url: 'communities',
      cache: false,
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
      // To ensure we get the placeholder text when user clicks selection then back button (firefox)
      $(this).val(null).trigger("change");
      window.location.href = data.path;
    }
  });
});
