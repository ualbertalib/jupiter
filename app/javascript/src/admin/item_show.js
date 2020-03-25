document.addEventListener('turbolinks:load', () => {
  $('#edit-history-hidden').on('hidden.bs.collapse shown.bs.collapse', () => {
    $('.js-edit-history-shown').toggleClass('d-none');
    $('.js-edit-history-hidden').toggleClass('d-none');
  });
});
