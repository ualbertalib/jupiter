$(document).on('turbolinks:load', function() {
  $(".js-skip-to-content").click(function (event) {
    $('#content').attr('tabIndex', -1).focus();
    event.preventDefault();
  });

  $(".js-skip-to-results").click(function (event) {
    $('#results').attr('tabIndex', -1).focus();
    event.preventDefault();
  });
});
