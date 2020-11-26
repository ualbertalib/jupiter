require 'test_helper'

class Digitization::BookTest < ActiveSupport::TestCase

  setup do
    @document = digitization_books(:folk_fest)
  end

  test 'valid Peel book' do
    assert @document.valid?
  end

  test 'unique Peel book' do
    book = Digitization::Book.create(peel_id: '10572', part_number: '1')
    assert_not book.valid?
    assert_equal('has already been taken', book.errors[:peel_id].first)
  end

  test 'invalid Peel book without peel id' do
    @document.assign_attributes(peel_id: nil, run: nil, part_number: '1')
    assert_not @document.valid?
    assert_equal("can't be blank", @document.errors[:peel_id].first)
  end

  test 'invalid Peel book from a run' do
    book = Digitization::Book.create(peel_id: '4242', run: '1')
    assert_not book.valid?
    assert_equal("can't be blank", book.errors[:part_number].first)
  end

  test 'valid Peel book from a run' do
    book = digitization_books(:henderson)
    assert book.valid?
  end

end
