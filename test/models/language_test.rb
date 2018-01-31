require 'test_helper'

class LanguageTest < ActiveSupport::TestCase

  context 'associations' do
    should have_many(:draft_items_languages).dependent(:destroy)
    should have_many(:draft_items).through(:draft_items_languages)
  end

  context 'methods' do
    context '#translated_name' do
      should 'give the translated version of the name' do
        english_language = languages(:english)
        assert_equal english_language.name, 'english'
        assert_equal english_language.translated_name, 'English'
      end
    end
  end

end
