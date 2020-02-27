import Dropzone from 'dropzone/dist/dropzone';

document.addEventListener('turbolinks:load', () => {
  // Disable auto discover for all elements:
  Dropzone.autoDiscover = false;

  if (document.querySelector('form.js-files-dropzone') !== null) {
    const filesDropzone = new Dropzone('form.js-files-dropzone', {
      paramName: 'file',
      maxFilesize: 1024, // default is 256 MB, lets bump to 1 GB
      timeout: 3600000, // default is 30 seconds, lets bump to 5 minutes
      createImageThumbnails: false,
      previewTemplate: $('#js-dropzone-preview-template').html(),
      previewsContainer: '#js-previews-list', // Define the container to display the previews
      clickable: '.js-add-files', // Define the element that should be used as click trigger to select files.

      init() {
        this.on('success', (file, response) => {
          $('#js-files-list').hide();
          $('#js-files-list').html(response.files_list_html).fadeIn(500);

          setTimeout(() => {
            filesDropzone.removeFile(file);
          }, 1000);
        });
      },
    });
  }
});
