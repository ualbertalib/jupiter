require 'test_helper'

class UpdateUserActivityJobTest < ActiveSupport::TestCase

  test 'should update the user activity (last seen at and IP) through the job' do
    user = users(:user_admin)
    ip = '4.73.73.73'
    now = Time.now.utc.to_s
    UpdateUserActivityJob.perform_now(user.id, now, ip)
    user.reload
    assert_equal user.last_seen_at.to_s, now
    assert_equal user.last_seen_ip, ip
    # Still does not change sign-in information
    assert_predicate user.last_sign_in_at, :blank?
    assert_predicate user.last_sign_in_ip, :blank?
    assert_predicate user.previous_sign_in_at, :blank?
    assert_predicate user.previous_sign_in_ip, :blank?
  end

end
