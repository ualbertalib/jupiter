document.addEventListener('turbolinks:load', () => {
  $('.js-download-all').click((event) => {
    event.preventDefault();
    $('.js-download').multiDownload();
  });

  $('#more-information-hidden').on('hidden.bs.collapse shown.bs.collapse', () => {
    $('.js-more-information-shown').toggleClass('d-none');
    $('.js-more-information-hidden').toggleClass('d-none');
  });

  $('#edit-history-hidden').on('hidden.bs.collapse shown.bs.collapse', () => {
    $('.js-edit-history-shown').toggleClass('d-none');
    $('.js-edit-history-hidden').toggleClass('d-none');
  });
});
