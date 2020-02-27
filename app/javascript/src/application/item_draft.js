let unsavedChanges = false;

// Find collection select
function collectionSelect($element) {
  const $root = $element.hasClass('.js-community-collection') ? $element : $element.closest('.js-community-collection');
  return $root.find('.js-collection-select');
}

function toggleRemoveVisibility() {
  if ($('div.js-community-collection').length > 1) {
    $('.js-remove-community-collection').show();
  } else {
    $('.js-remove-community-collection').hide();
  }
}

function addCommunityCollectionInput() {
  const $newInput = $('div.js-community-collection').first().clone();
  // Clear selections and disable collection select
  $newInput.find('.js-community-select').val(null);
  collectionSelect($newInput).attr('disabled', true).val(null);

  $newInput.appendTo('.js-communities-collections-list');
  toggleRemoveVisibility();
}

function removeCommunityCollectionInput($link) {
  if ($('div.js-community-collection').length > 1) {
    $link.closest('div.js-community-collection').remove();
    toggleRemoveVisibility();
  }
}

function toggleIcon(e) {
  $(e.target).prev('.card-header')
    .find('.js-more-less')
    .toggleClass('fa-chevron-down fa-chevron-up');
}

function fetchCollections() {
  const $collectionSelect = collectionSelect($(this));
  const id = $(this).find('option:selected').val();
  if (!id) {
    $collectionSelect.prop('disabled', true).empty();
  } else {
    $.getJSON(`/communities/${id}.json`).done((data) => {
      let items = `<option value>${$collectionSelect.data('placeholder')}</option>`;
      $.each(data.collections, (idx, item) => {
        items += `<option value="${item.id}">${item.title}</option>`;
      });
      $collectionSelect.prop('disabled', false).empty().append(items);
    });
  }
}

document.addEventListener('turbolinks:load', () => {
  unsavedChanges = false;

  toggleRemoveVisibility();

  $('#js-license-accordion .card').on('hidden.bs.collapse', toggleIcon);
  $('#js-license-accordion .card').on('shown.bs.collapse', toggleIcon);

  $('#js-additional-fields-accordion .card').on('hidden.bs.collapse', toggleIcon);
  $('#js-additional-fields-accordion .card').on('shown.bs.collapse', toggleIcon);


  $('form.js-deposit-item').on('change', 'input, select, textarea', () => {
    unsavedChanges = true;
  });

  $('form.js-deposit-item').submit(() => {
    unsavedChanges = false;
  });

  // disables links to future steps
  $('.nav-item .disabled').click((e) => {
    e.preventDefault();
  });

  $('form.js-deposit-item .js-add-community-collection').click((e) => {
    e.preventDefault();
    addCommunityCollectionInput();
  });

  $('form.js-deposit-item').on('click', '.js-remove-community-collection', (e) => {
    e.preventDefault();
    removeCommunityCollectionInput($(this));
  });

  $('form.js-deposit-item').on('change', '.js-community-select', fetchCollections);

  // global selectize initailization could be moved elsewhere
  $('.js-selectize').selectize({
    selectOnTab: true,
    closeAfterSelect: true,
  });

  // This one is for tagging/ability to create items on input
  $('.js-selectize-create').selectize({
    delimiter: '|', // We want | to seperate items (Authors names for example, `Doe, Jane B. | Deer, John A.' )
    persist: false,
    createOnBlur: true,
    create(input) {
      return {
        value: input,
        text: input,
      };
    },
  });
});

$(document).on('turbolinks:before-visit', () => {
  if (unsavedChanges) {
    // eslint-disable-next-line no-alert
    return window.confirm('Any changes you have made will NOT be saved. Are you sure you want to leave?');
  }
  return undefined;
});

$(window).bind('beforeunload', (event) => {
  if (unsavedChanges) {
    const msg = 'Any changes you have made will NOT be saved. Are you sure you want to leave?';
    // eslint-disable-next-line no-param-reassign
    event.returnValue = msg;
    return msg;
  }

  return undefined;
});
