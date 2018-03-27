$(document).on('turbolinks:load', function() {
  // Toggle between 'Show more...' and 'Hide' for longer lists of facets
  $('.js-hideshow-control')
    .on('click', function() {
      var $hideshow = $(this).closest('.js-hideshow');
      $hideshow.find('.js-hideshow-control').toggleClass('d-none');
    });

  // Filter/facet sidebar open (on small screens)
  $('.js-filters-open').on('click', function (event) {
    event.preventDefault();

    // fade in the overlay
    $('.filters-overlay').fadeIn();
    // open sidebar
    $('.jupiter-filters').toggleClass('d-none');
  });

  // Filter/facet sidebar close (on small screens)
  $('.js-filters-close, .overlay').on('click', function (event) {
    event.preventDefault();

    // hide the sidebar
    $('.jupiter-filters').toggleClass('d-none');
    // fade out the overlay
    $('.filters-overlay').fadeOut();
  });

});
