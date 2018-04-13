require 'test_helper'

class TypeTest < ActiveSupport::TestCase

# TODO: tests with shoulda-matchers
  # context 'associations' do
  #   should have_many(:draft_items).dependent(:nullify)
  # end

  test 'should give the translated version of the name' do
    book_type = types(:book)
    assert_equal book_type.name, 'book'
    assert_equal book_type.translated_name, 'Book'
  end

end
