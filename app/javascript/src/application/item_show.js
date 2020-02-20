$(document).on('turbolinks:load', function() {
  $('.js-download-all').click(function (event) {
    event.preventDefault();
    $('.js-download').multiDownload();
  });

  $('#more-information-hidden').on('hidden.bs.collapse', function() {
    $('.js-shown-text').toggleClass('d-none');
    $('.js-hidden-text').toggleClass('d-none');
  });
  $('#more-information-hidden').on('shown.bs.collapse', function() {
    $('.js-shown-text').toggleClass('d-none');
    $('.js-hidden-text').toggleClass('d-none');
  });
});
