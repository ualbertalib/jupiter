require 'test_helper'

class Digitization::NewspaperTest < ActiveSupport::TestCase

  setup do
    @newspaper = digitization_newspapers(:central_alberta_news)
  end

  test 'valid Peel newspaper' do
    assert @newspaper.valid?
  end

  test 'unique Peel newspaper' do
    newspaper = Digitization::Newspaper.create(publication_code: 'ACN',
                                               year: '1907',
                                               month: '08',
                                               day: '29')
    assert_not newspaper.valid?
    assert_equal('has already been taken', newspaper.errors[:publication_code].first)
    newspaper.destroy
  end

  test 'invalid Peel newspaper' do
    @newspaper.assign_attributes(year: nil, month: nil, day: nil)
    assert_not @newspaper.valid?
    assert_equal("can't be blank", @newspaper.errors[:year].first)
    assert_equal("can't be blank", @newspaper.errors[:month].first)
    assert_equal("can't be blank", @newspaper.errors[:day].first)
  end

  test 'should have required attributes' do
    @newspaper.assign_attributes(title: nil, genres: nil, languages: nil)
    assert_not @newspaper.valid?
    assert_equal("can't be blank", @newspaper.errors[:title].first)
    assert_equal("can't be blank", @newspaper.errors[:genres].first)
    assert_equal("can't be blank", @newspaper.errors[:languages].first)
  end

  test 'unknown resource types are not valid' do
    @newspaper.assign_attributes(resource_type: 'some_fake_resource_type')
    assert_not @newspaper.valid?
    assert_includes @newspaper.errors[:resource_type], 'is not recognized'
  end

  test 'unknown genres are not valid' do
    @newspaper.assign_attributes(genres: ['some_fake_genre'])
    assert_not @newspaper.valid?
    assert_includes @newspaper.errors[:genres], 'is not recognized'
  end

  test 'unknown languages are not valid' do
    @newspaper.assign_attributes(languages: ['some_fake_language'])
    assert_not @newspaper.valid?
    assert_includes @newspaper.errors[:languages], 'is not recognized'
  end

  test 'unknown rights are not valid' do
    @newspaper.assign_attributes(rights: 'some_fake_right')
    assert_not @newspaper.valid?
    assert_includes @newspaper.errors[:rights], 'is not recognized'
  end

  test 'dates must conform to EDTF format' do
    @newspaper.assign_attributes(dates_issued: ['INVALID DATE'])
    assert_not @newspaper.valid?
    assert_equal('does not conform to the Extended Date/Time Format standard', @newspaper.errors[:dates_issued].first)
  end

end
