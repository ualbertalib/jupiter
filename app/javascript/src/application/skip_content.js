document.addEventListener('turbolinks:load', () => {
  $('.js-skip-to-content').click(function skipToContent(event) {
    $($(this).attr('href')).attr('tabIndex', -1).focus();
    event.preventDefault();
  });
});
