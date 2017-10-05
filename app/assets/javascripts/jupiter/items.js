$(document).on('turbolinks:load', function() {
	$("#new_item #community").change(function() {
		update_collections();
	});

	$("#new_item .add-file").click(function(event){
		event.preventDefault();
		new_file_input();
	});

});

function update_collections() {
	id =  $("option:selected", '#new_item #community').val();

	$.getJSON('/communities/' + id + '.json').done(function(data) {
		var items = "";
		$.each(data, function(idx, item) {
			items += '<option value="' + item.id + '">' + item.title + '</option>';
		});
		$('#new_item #collection').empty().removeAttr('disabled').append(items);
	});
}

function new_file_input() {
	$("div.item_file").first().clone().appendTo('.file_upload');
}
