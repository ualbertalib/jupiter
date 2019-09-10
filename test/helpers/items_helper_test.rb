require 'test_helper'

class ItemsHelperTest < ActionView::TestCase

  test 'should return human readable date' do
    assert_equal t('date_unknown'), humanize_date('')
    assert_equal '2017-09-12', humanize_date('2017/09/12')
    assert_equal '2013', humanize_date('2013')
    assert_equal '2012-09-26', humanize_date('2012-09-26T11:18:38Z')
    assert_equal 'Fall 1978', humanize_date('Fall 1978')
    assert_equal 'Fall 1978', humanize_date('1978-11')
    assert_equal '1978', humanize_date('1978-01')
    assert_equal 'Unknown', humanize_date('Unknown')
    assert_equal 'Late Roman antiquity', humanize_date('Late Roman antiquity')
  end

end
