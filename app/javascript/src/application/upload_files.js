import Dropzone from 'dropzone/dist/dropzone';

$(document).on('turbolinks:load', function() {

  // Disable auto discover for all elements:
  Dropzone.autoDiscover = false;

  if (document.querySelector('form.js-files-dropzone') !== null ) {
    var filesDropzone = new Dropzone('form.js-files-dropzone', {
      paramName: 'file',
      maxFilesize: 1024, // default is 256 MB, lets bump to 1 GB
      timeout: 3600000, // default is 30 seconds, lets bump to 5 minutes

      // TODO: Need a decision here. Currently turned off image thumbnails as we allow many different file types
      // Probably okay to keep this turned off since these files only show up in this dropzone list for 1 second before getting appended
      // to the upload list, where we do a much better job of handling thumbnails for all file types
      createImageThumbnails: false, // TODO: Need a nice default image or better way to handle thumbnailing non-image types

      // acceptedFiles: 'image/*', TODO: is there a full list of what we accept? or do we just allow all file types? Like .exe files etc.
      previewTemplate: $('#js-dropzone-preview-template').html(),
      previewsContainer: '#js-previews-list', // Define the container to display the previews
      clickable: '.js-add-files', // Define the element that should be used as click trigger to select files.

      init: function() {

        // TODO: See decision above regarding `createImageThumbnails` option, if we don't care about thumbnails this all can be removed
        // this.on('addedfile', function(file) {
        //   if (!file.type.match(/image.*/)) {
        //     // This is not an image, so Dropzone doesn't create a thumbnail.
        //     // Set a default thumbnail:
        //     filesDropzone.emit("thumbnail", file, '/images/default_todo.jpg');
        //   }
        // });

        this.on('success', function(file, response) {
          $("#js-files-list").hide();
          $("#js-files-list").html(response.files_list_html)
                             .fadeIn(500);

          setTimeout(function() {
            filesDropzone.removeFile(file);
          }, 1000);
        });
      }
    });
  }
});
