// Replace thumbnail with default thumbnail on error
function default_thumbnail($element) {
  if ($element.parentElement.getElementsByClassName("img-thumbnail").length > 1) return;
  $element.error = null;
  $element.style.display = 'none';
  $thumbnail_html = "<div class='text-muted text-center img-thumbnail p-3'><i class='fa fa-file-o fa-5x'></i></div>";
  $element.insertAdjacentHTML('beforebegin', $thumbnail_html);
}
