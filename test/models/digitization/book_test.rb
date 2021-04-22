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
    @document.assign_attributes(temporal_subjects: nil, geographic_subjects: nil, topical_subjects: nil)
    assert_not @document.valid?
    assert_equal("can't be blank", @document.errors[:temporal_subjects].first)
    assert_equal("can't be blank", @document.errors[:geographic_subjects].first)
    assert_equal("can't be blank", @document.errors[:topical_subjects].first)
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

  test 'unknown genresss are not valid' do
    @document.assign_attributes(genres: ['some_fake_genres'])
    assert_not @document.valid?
    assert_includes @document.errors[:genres], 'is not recognized'
  end

  test 'unknown languages are not valid' do
    @document.assign_attributes(languages: ['some_fake_language'])
    assert_not @document.valid?
    assert_includes @document.errors[:languages], 'is not recognized'
  end

  test 'unknown rights are not valid' do
    @document.assign_attributes(rights: 'some_fake_right')
    assert_not @document.valid?
    assert_includes @document.errors[:rights], 'is not recognized'
  end

  test 'dates must conform to EDTF format' do
    @document.assign_attributes(dates_issued: ['INVALID DATE'], temporal_subjects: ['INVALID DATE'])
    assert_not @document.valid?
    assert_equal('does not conform to the Extended Date/Time Format standard',
                 @document.errors[:temporal_subjects].first)
    assert_equal('does not conform to the Extended Date/Time Format standard', @document.errors[:dates_issued].first)
  end

end
