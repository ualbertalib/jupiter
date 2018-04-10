$(document).on('turbolinks:load', function() {
  $input = $(".js-communities-collections-searchbox");

  if($input.length > 0) {
    var options = {
      adjustWidth: false,
      getValue: "name",
      url: function(phrase) {
        // we use a relative url "communities.json" here as this will be used for both /admin and non admin (/) paths
        return "communities.json?query=" + phrase;
      },
      categories: [
        {
          maxNumberOfElements:5,
          listLocation: "communities",
          header: "<strong>Communities</strong>",
        },
        {
          maxNumberOfElements:5,
          listLocation: "collections",
          header: "<strong>Collections</strong>",
        }
      ],
      list: {
        onChooseEvent: function() {
          var url = $input.getSelectedItemData().url;
          $input.val("");
          Turbolinks.visit(url);
        }
      }
    };

    $input.easyAutocomplete(options);
  }

});
