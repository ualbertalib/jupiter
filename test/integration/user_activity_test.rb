require 'test_helper'

class UserActivityTest < ActionDispatch::IntegrationTest

  include ActiveJob::TestHelper

  test 'signing-in calls User#update_activity! to update user activity' do
    # Sign-in calls `UpdateUserActivityJob.perform_now`, but this doesn't allow for testing
    # with the ActiveJob test helpers. Can't stub either on arbitrary instances of UpdateUserActivityJob
    # without pulling in another gem, so we test the effect on User directly.
    # See also test/jobs/update_user_activity_job_test.rb for expanded tests.

    # First sign-in
    now1 = nil
    freeze_time do
      now1 = Time.now.utc.to_s
      user = users(:regular_user)
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
      user = users(:regular_user)
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

  test 'visiting a page after a sufficient time enqueues a job to update user activity' do
    user = users(:regular_user)
    sign_in_as user

    # Less than five minutes
    travel 4.minutes do
      assert_no_enqueued_jobs do
        get communities_url
      end
    end

    # More than five minutes
    travel 6.minutes do
      now = Time.now.utc.to_s
      assert_enqueued_with(job: UpdateUserActivityJob, args: [user.id, now, '127.0.0.1']) do
        get communities_url
      end
    end
  end

end
