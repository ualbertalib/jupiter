// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, or any plugin's
// vendor/assets/javascripts directory can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// compiled file. JavaScript code in this file should be added after the last require_* statement.
//
// Read Sprockets README (https://github.com/rails/sprockets#sprockets-directives) for details
// about supported directives.
//
//= require rails-ujs
//= require turbolinks
//= require jquery3
//= require popper
//= require bootstrap

// Note typeahead fork downloaded from:
// https://raw.githubusercontent.com/coopy/typeahead.js/fix-async-render-dist/dist/typeahead.bundle.min.js
// Fixes this bad bug: https://github.com/twitter/typeahead.js/pull/1212
// Typeahead is infrequently updated, so no estimated date for a fix in production script.
//= require typeahead.bundle

//= require_tree ./jupiter
