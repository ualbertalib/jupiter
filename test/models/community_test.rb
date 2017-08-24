require 'test_helper'

class CommunityTest < ActiveSupport::TestCase

  test 'visibility callback' do
    c = Community.new_locked_ldp_object(title: 'foo', owner: users(:admin).id)
    assert c.valid?
    assert_equal c.visibility, JupiterCore::VISIBILITY_PUBLIC
  end

  test 'needs title' do
    c = Community.new_locked_ldp_object(owner: users(:admin).id)
    refute c.valid?
  end

end
