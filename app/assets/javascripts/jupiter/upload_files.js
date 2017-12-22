
$(document).on('turbolinks:load', function() {

  // Disable auto discover for all elements:
  Dropzone.autoDiscover = false;

  if (document.querySelector('form.js-files-dropzone') !== null ) {
    var filesDropzone = new Dropzone('form.js-files-dropzone', {
      paramName: 'file',
      createImageThumbnails: false, // TODO: Need a nice default image or better way to handle thumbnailing non-image types
      // acceptedFiles: 'image/*', TODO: is there a full list of what we accept?
      previewTemplate: $('#js-dropzone-preview-template').html(),
      previewsContainer: '#js-previews-list', // Define the container to display the previews
      clickable: '.js-add-files', // Define the element that should be used as click trigger to select files.
      init: function() {

        // TODO:
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


