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
    assert_equal(1, Announcement.current.count)
    assert_includes Announcement.current, announcements(:current_announcement)
  end

  test 'past announcements scope' do
    assert_equal(2, Announcement.past.count)
    assert_includes Announcement.past, announcements(:past_announcement)
    assert_includes Announcement.past, announcements(:another_past_announcement)
  end

end
