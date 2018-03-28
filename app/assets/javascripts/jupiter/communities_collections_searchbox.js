$(document).on('turbolinks:load', function() {
  $input = $(".js-communities-collections-searchbox")

  var options = {
    getValue: "name",
    url: function(phrase) {
      // we use a relative url "communities.json" here as this will be used for both /admin and non admin (/) paths
      return "communities.json?query=" + phrase;
    },
    categories: [
      {
        listLocation: "communities",
        header: "<strong>Communities</strong>",
      },
      {
        listLocation: "collections",
        header: "<strong>Collections</strong>",
      }
    ],
    list: {
      onChooseEvent: function() {
        var url = $input.getSelectedItemData().url
        $input.val("")
        Turbolinks.visit(url)
      }
    }
  }

  $input.easyAutocomplete(options)
});
