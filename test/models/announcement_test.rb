require 'test_helper'

class AnnouncementTest < ActiveSupport::TestCase

  test 'associations' do
    assert belong_to(:user)
  end

  test 'validations' do
    assert validate_presence_of(:message)
    assert validate_length_of(:message).is_at_most(500)
    assert validate_presence_of(:user)
  end

  test 'current announcements scope' do
    assert Announcement.current.count == 1
    assert_includes Announcement.current, announcements(:announcement_current)
  end

  test 'past announcements scope' do
    assert Announcement.past.count == 2
    assert_includes Announcement.past, announcements(:announcement_past)
    assert_includes Announcement.past, announcements(:announcement_past_two)
  end

end
