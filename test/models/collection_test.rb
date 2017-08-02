require 'test_helper'

class CollectionTest < ActiveSupport::TestCase

  test 'tags' do
    collection = Collection.new_locked_ldp_object
    collection.tag = "asdf"

    binding.pry
  end
end
