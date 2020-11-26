require 'test_helper'

class Digitization::NewspaperTest < ActiveSupport::TestCase

  setup do
    @newspaper = digitization_newspapers(:la_survivance)
  end

  test 'valid Peel newspaper' do
    assert @newspaper.valid?
  end

  test 'unique Peel newspaper' do
    newspaper = Digitization::Newspaper.create(publication_code: 'LSV',
                                               year: '1967',
                                               month: '03',
                                               day: '29')
    assert_not newspaper.valid?
    assert_equal('has already been taken', newspaper.errors[:publication_code].first)
  end

  test 'invalid Peel newspaper' do
    newspaper = Digitization::Newspaper.create(publication_code: 'LSV')
    assert_not newspaper.valid?
    assert_equal("can't be blank", newspaper.errors[:year].first)
    assert_equal("can't be blank", newspaper.errors[:month].first)
    assert_equal("can't be blank", newspaper.errors[:day].first)
  end

end
