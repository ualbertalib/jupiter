require 'test_helper'

class UserTest < ActiveSupport::TestCase

  test 'associations' do
    assert have_many(:identities).dependent(:destroy)
    assert have_many(:announcements).dependent(:destroy)
    assert have_many(:draft_items).dependent(:destroy)
  end

  test '#email' do
    assert validate_presence_of(:email)
    assert validate_uniqueness_of(:email).case_insensitive
    assert allow_value('random@example.com').for(:email)
  end

  test '#name' do
    assert validate_presence_of(:name)
  end

  test 'should update the activity columns when not signing-in' do
    user = users(:regular)
    assert user.last_seen_at.blank?
    assert user.last_sign_in_at.blank?
    assert user.previous_sign_in_at.blank?

    ip1 = '4.26.50.50'
    now1 = Time.now.utc.to_s

    user.update_activity!(now1, ip1)
    user.reload

    assert user.last_seen_at.present?
    assert_equal user.last_seen_at.to_s, now1
    assert_equal user.last_seen_ip, ip1
    # Does not change sign-in information
    assert user.last_sign_in_at.blank?
    assert user.last_sign_in_ip.blank?
    assert user.previous_sign_in_at.blank?
    assert user.previous_sign_in_ip.blank?

    travel 1.hour do
      ip2 = '4.73.73.73'
      now2 = Time.now.utc.to_s
      refute_equal now2, now1
      UpdateUserActivityJob.perform_now(user.id, now2, ip2)
      user.reload
      assert_equal user.last_seen_at.to_s, now2
      assert_equal user.last_seen_ip, ip2
      # Still does not change sign-in information
      assert user.last_sign_in_at.blank?
      assert user.last_sign_in_ip.blank?
      assert user.previous_sign_in_at.blank?
      assert user.previous_sign_in_ip.blank?
    end
  end

  test 'should update the activity columns when signing-in' do
    user = users(:regular)
    assert user.last_seen_at.blank?
    assert user.last_sign_in_at.blank?
    assert user.previous_sign_in_at.blank?

    ip1 = '4.26.50.50'
    now1 = Time.now.utc.to_s

    user.update_activity!(now1, ip1, sign_in: true)
    user.reload
    assert user.last_seen_at.present?
    assert_equal user.last_seen_at.to_s, now1
    assert_equal user.last_seen_ip, ip1
    assert_equal user.last_sign_in_at.to_s, now1
    assert_equal user.last_sign_in_ip, ip1
    assert user.previous_sign_in_at.blank?
    assert user.previous_sign_in_ip.blank?

    travel 1.hour do
      ip2 = '4.73.73.73'
      now2 = Time.now.utc.to_s
      refute_equal now2, now1

      user.update_activity!(now2, ip2, sign_in: true)
      user.reload
      assert_equal user.last_seen_at.to_s, now2
      assert_equal user.last_seen_ip, ip2
      assert_equal user.last_sign_in_at.to_s, now2
      assert_equal user.last_sign_in_ip, ip2
      assert_equal user.previous_sign_in_at, now1
      assert_equal user.previous_sign_in_ip, ip1
    end
  end

end
