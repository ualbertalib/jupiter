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
    book.destroy
  end

  test 'invalid Peel book without peel id' do
    @document.assign_attributes(peel_id: nil, run: nil, part_number: '1')
    assert_not @document.valid?
    assert_equal("can't be blank", @document.errors[:peel_id].first)
  end

  test 'invalid Peel book from a run' do
    @document.assign_attributes(peel_id: '4242', run: '1', part_number: nil)
    assert_not @document.valid?
    assert_equal("can't be blank", @document.errors[:part_number].first)
  end

  test 'valid Peel book from a run' do
    book = digitization_books(:henderson)
    assert book.valid?
  end

  test 'should have at least one type of subject' do
    @document.assign_attributes(temporal_subject: nil, geographic_subject: nil, topical_subject: nil)
    assert_not @document.valid?
    assert_equal("can't be blank", @document.errors[:temporal_subject].first)
    assert_equal("can't be blank", @document.errors[:geographic_subject].first)
    assert_equal("can't be blank", @document.errors[:topical_subject].first)
  end

  test 'should have a title' do
    @document.assign_attributes(title: nil)
    assert_not @document.valid?
    assert_equal("can't be blank", @document.errors[:title].first)
  end

  test 'unknown resource types are not valid' do
    @document.assign_attributes(resource_type: 'some_fake_resource_type')
    assert_not @document.valid?
    assert_includes @document.errors[:resource_type], 'is not recognized'
  end

  test 'unknown genres are not valid' do
    @document.assign_attributes(genre: ['some_fake_genre'])
    assert_not @document.valid?
    assert_includes @document.errors[:genre], 'is not recognized'
  end

  test 'unknown languages are not valid' do
    @document.assign_attributes(language: ['some_fake_language'])
    assert_not @document.valid?
    assert_includes @document.errors[:language], 'is not recognized'
  end

  test 'unknown rights are not valid' do
    @document.assign_attributes(rights: 'some_fake_right')
    assert_not @document.valid?
    assert_includes @document.errors[:rights], 'is not recognized'
  end

end
