require 'test_helper'

class LanguageTest < ActiveSupport::TestCase

# TODO: tests with shoulda-matchers
  # context 'associations' do
  #   should have_many(:draft_items_languages).dependent(:destroy)
  #   should have_many(:draft_items).through(:draft_items_languages)
  # end

  test 'should give the translated version of the name' do
    english_language = languages(:english)
    assert_equal english_language.name, 'english'
    assert_equal english_language.translated_name, 'English'
  end

end
