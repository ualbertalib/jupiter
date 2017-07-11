require 'test_helper'

class WorkTest < ActiveSupport::TestCase

  def test_must_have_a_visibility
    work = Work.new_locked_ldp_object

    assert_nil work.visibility
  end

  def test_must_be_a_known_visibility
    work = Work.new_locked_ldp_object
    work.unlock_and_fetch_ldp_object do |unlocked_work|
      unlocked_work.visibility = :some_fake_visibility
    end
    assert_not work.valid?
    assert work.errors[:visibility].present?
    assert_includes work.errors[:visibility], 'some_fake_visibility is not a known visibility'
  end

  def test_visibilities_should_include_embargo
    assert_includes Work.valid_visibilities, :embargo
  end

  def test_embargo_should_validate_end_date
    work = Work.new_locked_ldp_object
    work.unlock_and_fetch_ldp_object do |unlocked_work|
      unlocked_work.visibility = :embargo
    end

    assert_not work.valid?
    assert work.errors[:embargo_end_date].present?
    assert_includes work.errors[:embargo_end_date], "can't be blank"
  end

end
