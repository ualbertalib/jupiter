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

  test 'should update the activity columns when not signing-in for new user without activity update' do
    user = users(:user_admin)
    assert user.last_seen_at.blank?
    assert user.last_sign_in_at.blank?
    assert user.previous_sign_in_at.blank?
  end

  test 'should update the activity columns when not signing-in' do
    user = users(:user_regular)

    ip = '4.26.50.50'
    now = Time.now.utc.to_s

    user.update_activity!(now, ip)
    user.reload

    assert user.last_seen_at.present?
    assert_equal user.last_seen_at.to_s, now
    assert_equal user.last_seen_ip, ip
    # Does not change sign-in information
    assert user.last_sign_in_at.blank?
    assert user.last_sign_in_ip.blank?
    assert user.previous_sign_in_at.blank?
    assert user.previous_sign_in_ip.blank?
  end

  test 'should update the activity columns when signing-in' do
    user = users(:user_regular)
    ip = '4.26.50.50'
    now = Time.now.utc.to_s

    user.update_activity!(now, ip, sign_in: true)
    user.reload
    assert user.last_seen_at.present?
    assert_equal user.last_seen_at.to_s, now
    assert_equal user.last_seen_ip, ip
    assert_equal user.last_sign_in_at.to_s, now
    assert_equal user.last_sign_in_ip, ip
    assert user.previous_sign_in_at.blank?
    assert user.previous_sign_in_ip.blank?
  end

  test 'should validate if it does not have an api key and it is not a system account' do
    user = User.new(
      name: 'User name',
      email: 'valid@example.com',
      system: false
    )

    assert user.valid?
  end

  test 'should validate if it has an api key and it is a system account' do
    User.system_user.delete
    user = User.new(
      name: 'System user',
      email: 'ditech@ualberta.ca',
      api_key_digest: BCrypt::Password.create('3eeb395e-63b7-11ea-bc55-0242ac130003'),
      system: true
    )

    assert user.valid?
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
