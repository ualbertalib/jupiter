document.addEventListener('turbolinks:load', () => {
  $('.js-download-all').click((event) => {
    event.preventDefault();
    $('.js-download').multiDownload();
  });

  $('#more-information-hidden').on('hidden.bs.collapse', () => {
    $('.js-shown-text').toggleClass('d-none');
    $('.js-hidden-text').toggleClass('d-none');
  });
  $('#more-information-hidden').on('shown.bs.collapse', () => {
    $('.js-shown-text').toggleClass('d-none');
    $('.js-hidden-text').toggleClass('d-none');
  });
});
