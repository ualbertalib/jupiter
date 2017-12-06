$("#skip-nav").click(function() {
    $('main').focus();
});
$("#skip-to-results").click(function() {
    $('main').blur();
    $("#results-anchor").focus();
});
