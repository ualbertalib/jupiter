if Rails.env.development? || Rails.env.test?

  require 'sdoc'
  require 'rdoc/task' # ensure this file is also required in order to use `RDoc::Task`

  RDoc::Task.new do |rdoc|
    rdoc.rdoc_dir = 'docs/rdoc'
    rdoc.generator = 'sdoc'
    # The Rails theme is a lot nicer than the default one
    rdoc.template = 'rails'
    rdoc.main = 'README.md'
    rdoc.rdoc_files.include('README.md', 'app/', 'lib/')
  end

end
