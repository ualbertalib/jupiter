// Toggle between 'Show' and 'Hide' link for collapsible
$(document).on('turbolinks:load', function() {
  $('.hideshow-control')
    .on('click', function() {
      var $hideshow = $(this).closest('.hideshow');
      $hideshow.find('.hideshow-control').toggle();
    })
});
