$(document).on('turbolinks:load', function() {


    $('button.close-btn').click(function(event) {
        community_id = $(this).data('communityId');

        $(this).hide();
        $(".collection-btn[data-community-id='" + community_id + "']").show();
        $("ul#" + community_id).hide();
        event.preventDefault();
    });
});
