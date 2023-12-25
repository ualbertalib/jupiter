// Entry point for the build script in your package.json


import 'core-js/stable';
import 'regenerator-runtime/runtime';
import Rails from '@rails/ujs';
import Turbolinks from 'turbolinks';
import * as ActiveStorage from '@rails/activestorage';

import 'trix';
import '@rails/actiontext';
import 'bootstrap/dist/js/bootstrap';
import 'selectize/dist/js/standalone/selectize';
import 'easy-autocomplete/dist/jquery.easy-autocomplete';
import 'jquery-multidownload/jquery-multidownload';

import 'src/application';

// Expose jquery so RJS (e.g: js.erb templates) works properly
window.$ = $;

ActiveStorage.start();
Rails.start();
Turbolinks.start();
