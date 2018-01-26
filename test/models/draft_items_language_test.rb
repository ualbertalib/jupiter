require 'test_helper'

class DraftItemsLanguageTest < ActiveSupport::TestCase

  context 'associations' do
    should belong_to(:language)
    should belong_to(:draft_item)
  end

end
