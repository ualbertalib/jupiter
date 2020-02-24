document.addEventListener('turbolinks:load', () => {
  $('button.js-close-btn').click((event) => {
    const communityId = $(this).data('communityId');

    $(this).hide();
    $(`.js-collection-btn[data-community-id='${communityId}']`).show();
    $(`ul#${communityId}`).hide();
    event.preventDefault();
  });
});
