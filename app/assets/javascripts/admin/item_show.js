$(document).on('turbolinks:load', function() {
  $('#edit-history-hidden').on('hidden.bs.collapse shown.bs.collapse', function() {
    $('.js-edit-history-shown').toggleClass('d-none');
    $('.js-edit-history-hidden').toggleClass('d-none');
  });
});
