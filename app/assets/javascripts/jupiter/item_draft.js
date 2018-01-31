var unsavedChanges = false;

$(document).on('turbolinks:load', function() {
  unsavedChanges = false;

  toggle_remove_visibility();

  $('#js-license-accordion .card').on('hidden.bs.collapse', toggleIcon);
  $('#js-license-accordion .card').on('shown.bs.collapse', toggleIcon);

  $('#js-additional-fields-accordion .card').on('hidden.bs.collapse', toggleIcon);
  $('#js-additional-fields-accordion .card').on('shown.bs.collapse', toggleIcon);


  $('form.js-deposit-item').on('change', 'input, select, textarea', function() {
    unsavedChanges = true;
  });

  $('form.js-deposit-item').submit(function() {
    unsavedChanges = false;
  });

  // disables links to future steps
  $('.nav-item .disabled').click(function(e){
    e.preventDefault();
  });

  $('form.js-deposit-item .js-add-community-collection').click(function(e) {
    e.preventDefault();
    add_community_collection_input();
  });

  $('form.js-deposit-item').on('click', '.js-remove-community-collection', function() {
      event.preventDefault();
      remove_community_collection_input($(this));
    });

  $('form.js-deposit-item').on('change', '.js-community-select', function() {
    var $collectionSelect = collection_select($(this));
    var id =  $(this).find('option:selected').val();
    if (!id) {
      $collectionSelect.prop('disabled', true).empty();
    } else {
      $.getJSON('/communities/' + id + '.json').done(function(data) {
        var items = '<option value>' + $collectionSelect.data('placeholder') + '</option>';
        $.each(data.collections, function(idx, item) {
          items += '<option value="' + item.id + '">' + item.title + '</option>';
        });
        $collectionSelect.prop('disabled', false)
                         .empty().append(items);
      });
    }
  });

  // global select2 initailization (could be moved elsewhere)
  // We going to make heavy use of data-attrs to customize this
  // instead of intializing a many select2 methods with different options
  $('.js-select2').select2({
    theme: 'bootstrap',
    allowClear: true,

    // TODO: Hack on width which fixes mobile responsiveness width and select2 inputs being
    // a larger width then normal bootstrap inputs
    // See deposit_item.scss for similar comments.
    // Potential fix here: https://github.com/select2/select2/pull/4898/
    width: '100%'
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

// Find collection select
function collection_select($element) {
  var $root = $element.hasClass('.js-community-collection') ? $element : $element.closest('.js-community-collection');
  return $root.find('.js-collection-select');
}

function add_community_collection_input() {
  var $new_input = $("div.js-community-collection").first().clone();
  // Clear selections and disable collection select
  $new_input.find('.js-community-select').val(null);
  collection_select($new_input).attr('disabled', true).val(null);

  $new_input.appendTo('.js-communities-collections-list');
  toggle_remove_visibility();
}

function remove_community_collection_input($link) {
  if ($('div.js-community-collection').length > 1) {
    $link.closest('div.js-community-collection').remove();
    toggle_remove_visibility();
  }
}

function toggle_remove_visibility() {
  if ($('div.js-community-collection').length > 1) {
    $('.js-remove-community-collection').show();
  } else {
    $('.js-remove-community-collection').hide();
  }
}

function toggleIcon(e) {
  $(e.target).prev('.card-header')
             .find('.js-more-less')
             .toggleClass('fa-chevron-down fa-chevron-up');
}
