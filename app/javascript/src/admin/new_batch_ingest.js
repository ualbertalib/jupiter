function addFileInput(fileBtn) {
  const input = `<div>
    <input type="checkbox" name='batch_ingest[file_ids][]' value="${fileBtn.data('id')}" checked>
    <input type="hidden" name='batch_ingest[file_names][]' value="${fileBtn.data('name')}">
    <label for="batch_ingest[file_ids][]">${fileBtn.data('name')}</label>
  </div>`;

  $('.js-google-files-list').append(input);
  fileBtn.attr('disabled', true);
}

function addSpreadsheetInput(spreadsheetBtn) {
  const input = `<div>
    <input type="checkbox" name='batch_ingest[spreadsheet_id]' value="${spreadsheetBtn.data('id')}" checked>
    <input type="hidden" name='batch_ingest[spreadsheet_name]' value="${spreadsheetBtn.data('name')}">
    <label for="batch_ingest[spreadsheet_id]">${spreadsheetBtn.data('name')}</label>
  </div>`;

  $('.js-google-spreadsheet').append(input);
  spreadsheetBtn.attr('disabled', true);
}

// function removeFileInput($link) {
//   if ($('div.js-google-file').length > 1) {
//     $link.closest('div.js-google-file').remove();
//   }
// }

document.addEventListener('turbolinks:load', () => {
  $('.js-google-files-table').on('click', '.js-add-google-file', function addFile(e) {
    e.preventDefault();
    addFileInput($(this));
  });

  $('.js-google-spreadsheets-table').on('click', '.js-add-google-spreadsheet', function addSpreadsheet(e) {
    e.preventDefault();
    addSpreadsheetInput($(this));
  });

  // $('.js-google-files-table').on('click', '.js-remove-google-file', function removeFile(e) {
  //   e.preventDefault();
  //   removeFileInput($(this));
  // });
});
