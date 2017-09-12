$(document).on('turbolinks:load', function() {
  // Show clear button 'X' only when text present in search box
  $('.has-clear input[type="search"]').on('input propertychange', function() {
    var $this = $(this);
    var visible = Boolean($this.val());
    if (visible) {
      $this.siblings('.search-clear').show();
    }
    else {
      $this.siblings('.search-clear').hide();
    }
  }).trigger('propertychange');

  // Clear search box when the 'X' is clicked
  $('.search-clear').click(function() {
    $(this).siblings('input[type="search"]').val('')
      .trigger('propertychange').focus();
  });
});
