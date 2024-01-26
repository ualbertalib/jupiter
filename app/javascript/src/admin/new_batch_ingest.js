/* eslint-disable no-undef */

function addFileInput(id, name) {
  if (
    $('.js-batch-ingest-files-list').find(`input[value='${id}']`).length === 0
  ) {
    const input = `<li class="list-group-item d-flex justify-content-between">
        <input type="hidden" name="batch_ingest[batch_ingest_files_attributes][][google_file_name]" value="${name}">
        <input type="hidden" name="batch_ingest[batch_ingest_files_attributes][][google_file_id]" value="${id}">
        ${name}
        <button type="button" class="btn btn-danger btn-sm js-btn-delete-file">
          <i class="fa fa-trash-alt" aria-hidden="true"></i> Delete
        </button>
      </li>`;

    $('.js-batch-ingest-files-list').append(input);
  }
}

function addSpreadsheetInput(id, name) {
  const input = `<li class="list-group-item d-flex justify-content-between">
      <input type="hidden" name="batch_ingest[google_spreadsheet_name]" value="${name}">
      <input type="hidden" name="batch_ingest[google_spreadsheet_id]" value="${id}">
      ${name}
      <button type="button" class="btn btn-danger btn-sm js-btn-delete-file">
        <i class="fa fa-trash-alt" aria-hidden="true"></i> Delete
      </button>
    </li>`;

  $('.js-batch-ingest-spreadsheet').append(input);
  $('.js-btn-spreadsheet').addClass('d-none');
}

function deleteFileFromFilesList() {
  $(this).closest('li').remove();
}

function deleteSpreadsheet() {
  $(this).closest('li').remove();
  $('.js-btn-spreadsheet').removeClass('d-none');
}

function pickerFilesCallback(data) {
  if (data.action === google.picker.Action.PICKED) {
    data.docs.forEach((doc) => {
      addFileInput(doc.id, doc.name);
    });
  }
}

function pickerSpreadsheetCallback(data) {
  if (data.action === google.picker.Action.PICKED) {
    addSpreadsheetInput(data.docs[0].id, data.docs[0].name);
  }
}

function createFilesPicker() {
  const { developerKey, accessToken } = this.dataset;

  if (accessToken && developerKey) {
    const view = new google.picker.DocsView(google.picker.ViewId.DOCS);
    view.setMimeTypes(
      'application/epub+zip,'
        + 'application/excel,'
        + 'application/gzip,'
        + 'application/json,'
        + 'application/mp4,'
        + 'application/msword,'
        + 'application/octet-stream,'
        + 'application/pdf,'
        + 'application/postscript,'
        + 'application/rtf,'
        + 'application/sql,'
        + 'application/vnd.android.package-archive,'
        + 'application/vnd.ms-access,'
        + 'application/vnd.ms-asf,'
        + 'application/vnd.ms-excel,'
        + 'application/vnd.ms-excel.sheet.binary.macroenabled.12,'
        + 'application/vnd.ms-excel.sheet.macroenabled.12,'
        + 'application/vnd.ms-powerpoint,'
        + 'application/vnd.oasis.opendocument.text,'
        + 'application/vnd.openxmlformats-officedocument.presentationml.presentation,'
        + 'application/vnd.openxmlformats-officedocument.presentationml.slideshow,'
        + 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet,'
        + 'application/vnd.openxmlformats-officedocument.wordprocessingml.document,'
        + 'application/vnd.openxmlformats-officedocument.wordprocessingml.template,'
        + 'application/x-7z-compressed,'
        + 'application/x-bibtex,'
        + 'application/x-bibtex-text-file,'
        + 'application/x-ole-storage,'
        + 'application/x-rar,'
        + 'application/x-rar-compressed,'
        + 'application/x-spss-sav,'
        + 'application/x-tar,'
        + 'application/x-xz,'
        + 'application/x-zip-compressed,'
        + 'application/xml,'
        + 'application/zip,'
        + 'audio/mp4,'
        + 'audio/mpeg,'
        + 'audio/vnd.wave,'
        + 'audio/wav,'
        + 'audio/x-m4a,'
        + 'audio/x-mpegurl,'
        + 'audio/x-ms-asx,'
        + 'audio/x-ms-wma,'
        + 'audio/x-ms-wmv,'
        + 'audio/x-wav,'
        + 'audio/x-wave,'
        + 'image/gif,'
        + 'image/jpeg,'
        + 'image/png,'
        + 'image/svg+xml,'
        + 'image/tiff,'
        + 'inode/x-empty,'
        + 'message/rfc822,'
        + 'text/comma-separated-values,'
        + 'text/csv,'
        + 'text/html,'
        + 'text/plain,'
        + 'text/rtf,'
        + 'text/x-bibtex,'
        + 'text/x-csrc,'
        + 'text/x-matlab,'
        + 'text/x-objcsrc,'
        + 'text/x-r-source,'
        + 'text/x-r-sweave,'
        + 'video/mp4,'
        + 'video/mpeg,'
        + 'video/quicktime,'
        + 'video/x-flv,'
        + 'video/x-m4v,'
        + 'video/x-ms-wmv,'
        + 'video/x-msvideo',
    );
    view.setIncludeFolders(true);
    view.setParent('root');

    const picker = new google.picker.PickerBuilder()
      .setTitle('Select a file(s)')
      .enableFeature(google.picker.Feature.NAV_HIDDEN)
      .enableFeature(google.picker.Feature.MULTISELECT_ENABLED)
      .enableFeature(google.picker.Feature.SUPPORT_DRIVES)
      .setOAuthToken(accessToken)
      .addView(view)
      .setDeveloperKey(developerKey)
      .setCallback(pickerFilesCallback)
      .build();
    picker.setVisible(true);
  }
}

function createSpreadsheetPicker() {
  const { developerKey, accessToken } = this.dataset;

  if (accessToken && developerKey) {
    const view = new google.picker.View(google.picker.ViewId.SPREADSHEETS);
    view.setMimeTypes('application/vnd.google-apps.spreadsheet');
    view.setParent('root');

    const picker = new google.picker.PickerBuilder()
      .setTitle('Select a spreadsheet')
      .enableFeature(google.picker.Feature.NAV_HIDDEN)
      .setOAuthToken(accessToken)
      .addView(view)
      .setDeveloperKey(developerKey)
      .setCallback(pickerSpreadsheetCallback)
      .build();
    picker.setVisible(true);
  }
}

function registerClickEvents() {
  document
    .querySelector('.js-btn-spreadsheet')
    .addEventListener('click', createSpreadsheetPicker);
  document
    .querySelector('.js-btn-files')
    .addEventListener('click', createFilesPicker);
}

function loadAndInitGAPI() {
  return new Promise((resolve, reject) => {
    const script = document.createElement('script');
    script.type = 'text/javascript';
    script.src = 'https://apis.google.com/js/api.js';
    script.onload = (e) => {
      window.gapi.load('picker', { callback: registerClickEvents });
    };
    document.getElementsByTagName('head')[0].appendChild(script);
  });
}

document.addEventListener('turbolinks:load', () => {
  if (document.querySelector('.js-batch-ingest-spreadsheet')) {
    loadAndInitGAPI();
    $('.js-batch-ingest-spreadsheet').on(
      'click',
      '.js-btn-delete-file',
      deleteSpreadsheet,
    );
    $('.js-batch-ingest-files-list').on(
      'click',
      '.js-btn-delete-file',
      deleteFileFromFilesList,
    );
  }
});
