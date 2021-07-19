/* eslint-disable no-undef */

function addFileInput(id, name) {
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
}


function deleteFileFromFilesList() {
  $(this).closest('li').remove();
}

// TODO: Re-enable add spreadsheet button?
function deleteSpreadsheet() {
  $(this).closest('li').remove();
}


// TODO: check for duplicates?
function pickerFilesCallback(data) {
  if (data.action === google.picker.Action.PICKED) {
    data.docs.forEach((doc) => {
      addFileInput(doc.id, doc.name);
    });
  }
}

// TODO: Hide add spreadsheet button?
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
      'image/png,'
      + 'image/jpeg,'
      + 'image/jpg,'
      + 'audio/mpeg,'
      + 'video/mpeg,'
      + 'application/zip,'
      + 'text/plain,'
      + 'application/pdf,'
      + 'application/msword,'
      + 'application/vnd.ms-excel',
    );
    view.setIncludeFolders(true);
    view.setEnableDrives(true);
    // view.setParent('root');
    // TODO: Future? Have to break down folder into its files, or enhance backend job to consume a folder
    // view.setSelectFolderEnabled(true);

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
  document.querySelector('.js-btn-spreadsheet').addEventListener('click', createSpreadsheetPicker);
  document.querySelector('.js-btn-files').addEventListener('click', createFilesPicker);
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
  loadAndInitGAPI();
  $('.js-batch-ingest-spreadsheet').on('click', '.js-btn-delete-file', deleteSpreadsheet);
  $('.js-batch-ingest-files-list').on('click', '.js-btn-delete-file', deleteFileFromFilesList);
});
