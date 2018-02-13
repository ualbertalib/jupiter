if ($('.skip').length) {
  alert('this record already exists');
} else {
  // do stuff
}

$('.skip').keypress(function() {
    window.location.hash="";
    console.log("test")
    $('#results').focus();
});
