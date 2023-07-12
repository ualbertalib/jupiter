require 'test_helper'

class Digitization::FulltextTest < ActiveSupport::TestCase

  setup do
    @fulltext = digitization_fulltexts(:one)
  end

  test 'valid fulltext' do
    assert_predicate @fulltext, :valid?
  end

  test 'should have text' do
    @fulltext.assign_attributes(text: nil)

    assert_not @fulltext.valid?
    assert_equal("can't be blank", @fulltext.errors[:text].first)
  end

end
