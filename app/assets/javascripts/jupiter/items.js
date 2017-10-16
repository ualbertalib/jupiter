$(document).on('turbolinks:load', function() {
  $('form')
    .on('change', '.community-select', function() {
      update_collection_select($(this));
    })
    .on('click', '.add-community-collection', function() {
      event.preventDefault();
      add_community_collection_input();
    })
    .on('click', '.remove-community-collection', function() {
      event.preventDefault();
      remove_community_collection_input($(this));
    })
    .on('click', '.add-file', function(event){
      event.preventDefault();
      add_file_input();
    });
});

function update_collection_select($community_select) {
  var $collection_select = collection_select($community_select);
  var id =  $community_select.find('option:selected').val();
  // Bad value? Disable the collection select
  if (!id) {
    $collection_select.attr('disabled', true).val(null);
    return;
  }
  $.getJSON('/communities/' + id + '.json').done(function(data) {
    var items = "";
    $.each(data.collections, function(idx, item) {
      items += '<option value="' + item.id + '">' + item.title + '</option>';
    });
    $collection_select.empty().removeAttr('disabled').append(items);
  });
}

// Find collection select
function collection_select($element) {
  var $root = $element.hasClass('.community-collection') ? $element : $element.closest('.community-collection');
  return $root.find('.collection-select');
}

function add_community_collection_input() {
  var $new_input = $("div.community-collection").first().clone();
  // Clear selections and disable collection select
  $new_input.find('.community-select').val(null);
  collection_select($new_input).attr('disabled', true).val(null);

  $new_input.appendTo('.communities-collections-list');
}

function remove_community_collection_input($link) {
  if ($('div.community-collection').length > 1) {
    $link.closest('div.community-collection').remove();
  }
}

function add_file_input() {
  $("div.item_file").first().clone().appendTo('.file_upload');
}
