$(document).on('turbolinks:load', function() {

  function toggleIcon(e) {
    $(e.target)
      .prev('.card-header')
      .find('.js-more-less')
      .toggleClass('fa-plus fa-minus');
  }
  $('#license-accordion .card').on('hidden.bs.collapse', toggleIcon);
  $('#license-accordion .card').on('shown.bs.collapse', toggleIcon);

});
