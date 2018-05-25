require 'test_helper'

class IdentityTest < ActiveSupport::TestCase

  test 'associations' do
    assert belong_to(:user)
  end

  test '#provider' do
    assert validate_presence_of(:provider)
  end

  test '#uid' do
    assert validate_presence_of(:uid)
    assert validate_uniqueness_of(:uid).scoped_to(:provider)
  end

  test '#user_id' do
    assert validate_uniqueness_of(:user_id).scoped_to(:provider)
  end

end
