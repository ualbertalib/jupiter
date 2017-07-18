require 'test_helper'

class UserTest < ActiveSupport::TestCase

  context 'associations' do
    should have_many(:identities).dependent(:destroy)
  end

  context 'validations' do
    context '#email' do
      should validate_presence_of(:email)
      should validate_uniqueness_of(:email).case_insensitive
      should allow_value('random@example.com').for(:email)
    end

    context '#display_name' do
      should validate_presence_of(:display_name)
    end
  end

end
