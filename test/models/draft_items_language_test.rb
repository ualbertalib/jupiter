require 'test_helper'

class DraftItemsLanguageTest < ActiveSupport::TestCase

  test 'associations' do
    assert belong_to(:language)
    assert belong_to(:draft_item)
  end

end
