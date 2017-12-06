
$(document).on('turbolinks:load', function() {

  // Disable auto discover for all elements:
  Dropzone.autoDiscover = false;

  if (document.querySelector('form.js-dropzone') !== null) {
    // Get the template HTML and remove it from the document
    var previewNode = document.querySelector('#js-template');
    previewNode.id = '';
    var previewTemplate = previewNode.parentNode.innerHTML;
    previewNode.parentNode.removeChild(previewNode);


    var myDropzone = new Dropzone('form.js-dropzone', {
      paramName: 'item[files]',
      thumbnailWidth: 80,
      thumbnailHeight: 80,
      parallelUploads: 100,
      maxFiles: 100,
      previewTemplate: previewTemplate,
      autoProcessQueue: false,
      uploadMultiple: true,
      previewsContainer: '#js-previews', // Define the container to display the previews
      clickable: '.js-add-files', // Define the element that should be used as click trigger to select files.

      // The setting up of the dropzone
      init: function() {
        var myDropzone = this;

        // First change the button to actually tell Dropzone to process the queue.
        this.element.querySelector('button[type=submit]').addEventListener('click', function(e) {
          // Make sure that the form isn't actually being sent.
          e.preventDefault();
          e.stopPropagation();
          myDropzone.processQueue();
        });

        // Listen to the sendingmultiple event. In this case, it's the sendingmultiple event instead
        // of the sending event because uploadMultiple is set to true.
        this.on('sendingmultiple', function() {
          // Gets triggered when the form is actually being sent.
          // Hide the success button or the complete form.
        });

        this.on('successmultiple', function(files, response) {
          // Gets triggered when the files have successfully been sent.
          // Redirect user or notify of success.
          $('form.js-dropzone').submit();
        });

        this.on('errormultiple', function(files, response) {
          // Gets triggered when there was an error sending the files.
          // Maybe show form again, and notify user of error
        });
      }

    });

    document.querySelector('.js-dropzone .js-cancel-files').addEventListener('click', function() {
      myDropzone.removeAllFiles(true);
    });

    // Make files previews sortable
    var el = document.querySelector('#js-previews');
    var sortable = Sortable.create(el, {
      // Called by any change to the list (add / update / remove)
      onSort: function (/**Event*/evt) {
        // Get the queued files
        var files = myDropzone.getQueuedFiles();
        // Sort theme based on the DOM element index
        files.sort(function(a, b){
            return ($(a.previewElement).index() > $(b.previewElement).index()) ? 1 : -1;
        });
        // Clear the dropzone queue
        myDropzone.removeAllFiles();
        // Add the reordered files to the queue
        myDropzone.handleFiles(files);
      },
    });
  }
});


