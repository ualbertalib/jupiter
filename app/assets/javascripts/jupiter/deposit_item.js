var unsavedChanges = false;

$(document).on('turbolinks:load', function() {
  unsavedChanges = false;

  function toggleIcon(e) {
    $(e.target)
      .prev('.card-header')
      .find('.js-more-less')
      .toggleClass('fa-chevron-down fa-chevron-up');
  }

  $('#js-license-accordion .card').on('hidden.bs.collapse', toggleIcon);
  $('#js-license-accordion .card').on('shown.bs.collapse', toggleIcon);

  $('#js-additional-fields-accordion .card').on('hidden.bs.collapse', toggleIcon);
  $('#js-additional-fields-accordion .card').on('shown.bs.collapse', toggleIcon);


  $('form.js-deposit-item input').change(function() {
    return unsavedChanges = true;
  });

  $('form.js-deposit-item').submit(function() {
    return unsavedChanges = false;
  });

});

$(document).on('turbolinks:before-visit', function() {
  if (unsavedChanges) {
    return confirm("Any changes you have made will NOT be saved. Are you sure you want to leave?");
  }
});

$(window).bind('beforeunload', function(event) {
  if (unsavedChanges) {
    var msg = "Any changes you have made will NOT be saved. Are you sure you want to leave?";
    event.returnValue = msg;
    return msg;
  }
});
