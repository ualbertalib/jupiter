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

  // bring over community/collection select from items (tweaked a bit)
  // (we only need to handle one pairing for time being)
  $('form.js-deposit-item .js-community-select').change(function() {
    var id =  $(this).find('option:selected').val();
    if (!id) {
      $('.js-collection-select').prop('disabled', true).empty();
    } else {
      $.getJSON('/communities/' + id + '.json').done(function(data) {
        var items = "<option value>Select a collection</option>";

        $.each(data.collections, function(idx, item) {
          items += '<option value="' + item.id + '">' + item.title + '</option>';
        });
        $('.js-collection-select').prop('disabled', false)
                                  .empty().append(items);
      });
    }
  })

  // select2 initailizations
  $('.js-select2-languages').select2({
    theme: 'bootstrap',
    allowClear: true
  });

  $('.js-select2-tags').select2({
    theme: 'bootstrap',
    placeholder: 'Enter multiple values',
    tags: true,
    allowClear: true
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
