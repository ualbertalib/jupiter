How to generate new ERD diagram
---------------

See the [installation instructions](https://voormedia.github.io/rails-erd/install.html) for a complete description of how to install Rails ERD. Here's a summary:

* Install Graphviz 2.22+ ([how?](https://voormedia.github.io/rails-erd/install.html)). On macOS with Homebrew run `brew install graphviz`.

* Add <tt>gem 'rails-erd', group: :development</tt> to your application's Gemfile

* Run <tt>bundle exec erd</tt>

* Move the PDF to the docs folder
