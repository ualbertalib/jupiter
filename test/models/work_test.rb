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

  def test_add_to_path
    work = Work.new_locked_ldp_object
    community_id = generate_random_string
    collection_id = generate_random_string

    work.unlock_and_fetch_ldp_object do |unlocked_work|
      unlocked_work.add_to_path(community_id, collection_id)
    end

    assert_includes work.member_of_paths, "#{community_id}/#{collection_id}"
  end

  def test_display_attributes
    assert_not_includes Work.display_attribute_names, :member_of_paths
  end

end
