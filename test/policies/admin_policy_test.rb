require 'test_helper'

class AdminPolicyTest < ActiveSupport::TestCase

  test 'should deny normal user' do
    current_user = users(:user_regular)

    assert_not AdminPolicy.new(current_user, :admin).access?
  end

  test 'should allow admin user' do
    current_user = users(:user_admin)

    assert_predicate AdminPolicy.new(current_user, :admin), :access?
  end

end
