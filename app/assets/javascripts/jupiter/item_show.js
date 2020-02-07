$(document).on('turbolinks:load', function() {
  $('.js-download-all').click(function (event) {
    event.preventDefault();
    $('.js-download').multiDownload();
  });

  $('#more-information-hidden').on('hidden.bs.collapse', function() {
    $('.js-mi-shown-text').toggleClass('d-none');
    $('.js-mi-hidden-text').toggleClass('d-none');
  });
  $('#more-information-hidden').on('shown.bs.collapse', function() {
    $('.js-mi-shown-text').toggleClass('d-none');
    $('.js-mi-hidden-text').toggleClass('d-none');
  });

  $('#edit-history-hidden').on('hidden.bs.collapse', function() {
    $('.js-eh-shown-text').toggleClass('d-none');
    $('.js-eh-hidden-text').toggleClass('d-none');
  });
  $('#edit-history-hidden').on('shown.bs.collapse', function() {
    $('.js-eh-shown-text').toggleClass('d-none');
    $('.js-eh-hidden-text').toggleClass('d-none');
  });
});
