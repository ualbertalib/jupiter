/* eslint-disable no-undef */

function addFileInput(id, name) {
  const input = `<div>
    <input type="checkbox" name='batch_ingest[file_ids][]' value="${id}" checked>
    <input type="hidden" name='batch_ingest[file_names][]' value="${name}">
    <label for="batch_ingest[file_ids][]">${name}</label>
  </div>`;

  $('.js-google-files-list').append(input);
}

function addSpreadsheetInput(id, name) {
  const input = `<div>
    <input type="checkbox" name='batch_ingest[spreadsheet_id]' value="${id}" checked>
    <input type="hidden" name='batch_ingest[spreadsheet_name]' value="${name}">
    <label for="batch_ingest[spreadsheet_id]">${name}</label>
  </div>`;

  $('.js-google-spreadsheet').append(input);
}

function pickerSpreadsheetCallback(data) {
  if (data.action === google.picker.Action.PICKED) {
    addSpreadsheetInput(data.docs[0].id, data.docs[0].name);
  }
}

function pickerFilesCallback(data) {
  if (data.action === google.picker.Action.PICKED) {
    data.docs.forEach((doc) => {
      addFileInput(doc.id, doc.name);
    });
  }
}

function createSpreadsheetPicker() {
  const developerKey = 'AIzaSyBjRZF0gliGWQ6q1zdVlocqzwG1t1YRghw';
  const oauthToken = this.dataset.accessToken;

  if (oauthToken) {
    const view = new google.picker.View(google.picker.ViewId.SPREADSHEETS);
    view.setMimeTypes('application/vnd.google-apps.spreadsheet');

    const picker = new google.picker.PickerBuilder()
      .setTitle('Select a spreadsheet')
      .enableFeature(google.picker.Feature.NAV_HIDDEN)
      .setOAuthToken(oauthToken)
      .addView(view)
      .setDeveloperKey(developerKey)
      .setCallback(pickerSpreadsheetCallback)
      .build();
    picker.setVisible(true);
  }
}

function createFilesPicker() {
  const developerKey = 'AIzaSyBjRZF0gliGWQ6q1zdVlocqzwG1t1YRghw';
  const oauthToken = this.dataset.accessToken;

  if (oauthToken) {
    const picker = new google.picker.PickerBuilder()
      .setTitle('Select a file(s)')
      .enableFeature(google.picker.Feature.NAV_HIDDEN)
      .enableFeature(google.picker.Feature.MULTISELECT_ENABLED)
      .setOAuthToken(oauthToken)
      .addView(new google.picker.View(google.picker.ViewId.DOCS))
      .setDeveloperKey(developerKey)
      .setCallback(pickerFilesCallback)
      .build();
    picker.setVisible(true);
  }
}

function registerClickEvents() {
  document.querySelector('.btn-spreadsheet').addEventListener('click', createSpreadsheetPicker);
  document.querySelector('.btn-files').addEventListener('click', createFilesPicker);
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
});
