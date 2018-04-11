$(document).on('turbolinks:load', function() {
  $(".js-skip-to-content").click(function (event) {
    $($(this).attr('href')).attr('tabIndex', -1).focus();
    event.preventDefault();
  });
});
