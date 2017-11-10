// Toggle between 'Show' and 'Hide' link for collapsible
$(document).on('turbolinks:load', function() {
  $('.js-hideshow-control')
    .on('click', function() {
      var $hideshow = $(this).closest('.js-hideshow');
      $hideshow.find('.js-hideshow-control').toggle();
    });
});
