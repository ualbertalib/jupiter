require 'test_helper'

class UserActivityTest < ActionDispatch::IntegrationTest

  include ActiveJob::TestHelper

  test 'signing-in calls User#update_activity! to update user activity' do
    # Sign-in calls `UpdateUserActivityJob.perform_now`, but this doesn't allow for testing
    # with the ActiveJob test helpers. Can't stub either on arbitrary instances of UpdateUserActivityJob
    # without pulling in another gem, so we test the effect on User directly.

    # First sign-in
    now1 = nil
    freeze_time do
      now1 = Time.now.utc.to_s
      user = users(:regular)
      perform_enqueued_jobs do
        sign_in_as user
      end
      user.reload
      assert_equal user.last_seen_at.to_s, now1
      assert_equal user.last_seen_ip, '127.0.0.1'
      assert_equal user.last_sign_in_at.to_s, now1
    end

    get logout_url

    # Second sign-in
    travel 1.hour do
      now2 = Time.now.utc.to_s
      user = users(:regular)
      perform_enqueued_jobs do
        sign_in_as user
      end
      user.reload
      assert_equal user.last_seen_at.to_s, now2
      assert_equal user.last_seen_ip, '127.0.0.1'
      assert_equal user.last_sign_in_at.to_s, now2
      assert_equal user.previous_sign_in_at, now1
    end
  end

  test 'visiting a page after a sufficient time updates user activity' do
    user = users(:regular)
    sign_in_as user

    # Note, the previous line updated the columns of interest (won't be nil, stash values here)
    user.reload
    last_seen_at1 = user.last_seen_at
    last_seen_ip1 = user.last_seen_ip
    last_sign_in_at1 = user.last_sign_in_at

    # Less than five minutes in the future, user activity job doesn't run on page visit
    travel 4.minutes do
      perform_enqueued_jobs do
        get communities_url
      end
      assert_performed_jobs 0
      user.reload
      # Nothing change
      assert_equal user.last_seen_at, last_seen_at1
      assert_equal user.last_seen_ip, last_seen_ip1
      assert_equal user.last_sign_in_at, last_sign_in_at1
    end

    # More than five minutes, user activity job runs and `last_seen_at` changes
    travel 6.minutes do
      now = Time.now.utc.to_s
      perform_enqueued_jobs do
        get communities_url
      end
      assert_performed_jobs 1
      user.reload
      # `last_seen_at` changed
      refute_equal user.last_seen_at, last_seen_at1
      assert_equal user.last_seen_at.to_s, now
      # `last_seen_ip` and `last_sign_in_at` stay the same
      assert_equal user.last_seen_ip, last_seen_ip1
      assert_equal user.last_sign_in_at, last_sign_in_at1
    end
  end

end
