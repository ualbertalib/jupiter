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

  test '#flipper_id' do
    user = users(:user_regular)
    assert_equal "User:#{user.id}", user.flipper_id
  end

  # rubocop:disable Minitest/MultipleAssertions
  # TODO: our tests are quite smelly.  This one needs work!
  test 'should update the activity columns when not signing-in' do
    user = users(:user_regular)
    assert_predicate user.last_seen_at, :blank?
    assert_predicate user.last_sign_in_at, :blank?
    assert_predicate user.previous_sign_in_at, :blank?

    ip1 = '4.26.50.50'
    now1 = Time.now.utc.to_s

    user.update_activity!(now1, ip1)
    user.reload

    assert_predicate user.last_seen_at, :present?
    assert_equal user.last_seen_at.to_s, now1
    assert_equal user.last_seen_ip, ip1
    # Does not change sign-in information
    assert_predicate user.last_sign_in_at, :blank?
    assert_predicate user.last_sign_in_ip, :blank?
    assert_predicate user.previous_sign_in_at, :blank?
    assert_predicate user.previous_sign_in_ip, :blank?

    travel 1.hour do
      ip2 = '4.73.73.73'
      now2 = Time.now.utc.to_s
      assert_not_equal now2, now1
      UpdateUserActivityJob.perform_now(user.id, now2, ip2)
      user.reload
      assert_equal user.last_seen_at.to_s, now2
      assert_equal user.last_seen_ip, ip2
      # Still does not change sign-in information
      assert_predicate user.last_sign_in_at, :blank?
      assert_predicate user.last_sign_in_ip, :blank?
      assert_predicate user.previous_sign_in_at, :blank?
      assert_predicate user.previous_sign_in_ip, :blank?
    end
  end
  # rubocop:enable Minitest/MultipleAssertions

  # rubocop:disable Minitest/MultipleAssertions
  # TODO: our tests are quite smelly.  This one needs work!
  test 'should update the activity columns when signing-in' do
    user = users(:user_regular)
    assert_predicate user.last_seen_at, :blank?
    assert_predicate user.last_sign_in_at, :blank?
    assert_predicate user.previous_sign_in_at, :blank?

    ip1 = '4.26.50.50'
    now1 = Time.now.utc.to_s

    user.update_activity!(now1, ip1, sign_in: true)
    user.reload
    assert_predicate user.last_seen_at, :present?
    assert_equal user.last_seen_at.to_s, now1
    assert_equal user.last_seen_ip, ip1
    assert_equal user.last_sign_in_at.to_s, now1
    assert_equal user.last_sign_in_ip, ip1
    assert_predicate user.previous_sign_in_at, :blank?
    assert_predicate user.previous_sign_in_ip, :blank?

    travel 1.hour do
      ip2 = '4.73.73.73'
      now2 = Time.now.utc.to_s
      assert_not_equal now2, now1

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
  # rubocop:enable Minitest/MultipleAssertions

  test 'should validate if it does not have an api key and it is not a system account' do
    user = User.new(
      name: 'User name',
      email: 'valid@example.com',
      system: false
    )

    assert_predicate user, :valid?
  end

  test 'should validate if it has an api key and it is a system account' do
    User.system_user.delete
    user = User.new(
      name: 'System user',
      email: 'ditech@ualberta.ca',
      api_key_digest: BCrypt::Password.create('3eeb395e-63b7-11ea-bc55-0242ac130003'),
      system: true
    )

    assert_predicate user, :valid?
  end

  test 'should not validate if it has an api key and it is not a system account' do
    user = User.new(
      name: 'User name',
      email: 'valid@example.com',
      api_key: '70d800e9-5fe8-49e4-86ed-eefc11ebfa52'
    )

    assert_not user.valid?
    assert_equal user.errors[:api_key_digest].first,
                 I18n.t('activerecord.errors.models.user.attributes.api_key_digest.blank_if_system_false')
  end

  test 'should not validate if it does not have an api key and it is a system account' do
    user = User.new(
      name: 'User name',
      email: 'valid@example.com',
      system: true
    )

    assert_not user.valid?
    assert_equal user.errors[:api_key_digest].first,
                 I18n.t('activerecord.errors.models.user.attributes.api_key_digest.present_if_system_true')
  end

end
