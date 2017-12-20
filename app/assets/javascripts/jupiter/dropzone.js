
$(document).on('turbolinks:load', function() {

  // Disable auto discover for all elements:
  Dropzone.autoDiscover = false;

  if (document.querySelector('form.js-files-dropzone') !== null ) {
    var filesDropzone = new Dropzone('form.js-files-dropzone', {
      paramName: 'file',
      // thumbnailWidth: 80,
      // thumbnailHeight: 80,
      // parallelUploads: 100,
      // maxFiles: 100,
      // acceptedFiles: 'image/*', TODO: is there a full list of what we accept?
      previewTemplate: $('#js-dropzone-preview-template').html(),
      // autoProcessQueue: false,
      // uploadMultiple: true,
      previewsContainer: '#js-previews-list', // Define the container to display the previews
      clickable: '.js-add-files', // Define the element that should be used as click trigger to select files.
      init: function() {
        this.on('success', function(file, response) {
          $("#js-files-list").hide();
          $("#js-files-list").html(response.files_list_html)
                             .fadeIn(500);
        });
      }
    });

    document.querySelector('.js-files-dropzone .js-clear-files').addEventListener('click', function() {
      filesDropzone.removeAllFiles(true);
    });

    // Make files previews sortable
    // var el = document.querySelector('#js-previews');
    // var sortable = Sortable.create(el, {
    //   // Called by any change to the list (add / update / remove)
    //   onSort: function (/**Event*/evt) {
    //     // Get the queued files
    //     var files = filesDropzone.getQueuedFiles();
    //     // Sort theme based on the DOM element index
    //     files.sort(function(a, b){
    //         return ($(a.previewElement).index() > $(b.previewElement).index()) ? 1 : -1;
    //     });
    //     // Clear the dropzone queue
    //     filesDropzone.removeAllFiles();
    //     // Add the reordered files to the queue
    //     filesDropzone.handleFiles(files);
    //   },
    // });
  }
});


