require 'test_helper'

class AdminPolicyTest < ActiveSupport::TestCase

  test 'should deny normal user' do
    current_user = users(:regular_user)
    assert_equal false, AdminPolicy.new(current_user, :admin).access?
  end

  test 'should allow admin user' do
    current_user = users(:admin)
    assert AdminPolicy.new(current_user, :admin).access?
  end

end
