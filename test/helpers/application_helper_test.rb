require 'test_helper'

class ApplicationHelperTest < ActionView::TestCase

  test 'should return human readable string from either a URI or string' do
    assert_equal 'Edmonton (Alta.)', humanize_uri_or_literal(:digitization, :subject, 'http://id.loc.gov/authorities/names/n79007225')
    assert_equal 'Exactly this string.', humanize_uri_or_literal(:digitization, :subject, 'Exactly this string.')
    assert_nil humanize_uri_or_literal(:digitization, :subject, nil)
  end

end
