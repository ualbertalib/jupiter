$(document).on('turbolinks:load', function() {
  $('.js-download-all').click(function (event) {
    event.preventDefault();
    $('.js-download').multiDownload();
  });
});
