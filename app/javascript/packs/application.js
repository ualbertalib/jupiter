// This file is automatically compiled by Webpack, along with any other files
// present in this directory. You're encouraged to place your actual application logic in
// a relevant structure within app/javascript and only use these pack files to reference
// that code so it'll be compiled.

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

import '../styles/application.scss';
import '../src/application';

require.context('../images', true);

ActiveStorage.start();
Rails.start();
Turbolinks.start();
