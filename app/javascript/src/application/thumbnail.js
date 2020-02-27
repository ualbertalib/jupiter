// Replace thumbnail with default thumbnail on error
// eslint-disable-next-line no-unused-vars
export default function defaultThumbnail($element) {
  if ($element.parentElement.getElementsByClassName('img-thumbnail').length > 1) return;
  // eslint-disable-next-line no-param-reassign
  $element.error = null;
  // eslint-disable-next-line no-param-reassign
  $element.style.display = 'none';
  const $thumbnailHTML = `<div class='text-muted text-center img-thumbnail p-3'>
  <i class='far fa-file fa-5x'></i></div>`;
  $element.insertAdjacentHTML('beforebegin', $thumbnailHTML);
}
