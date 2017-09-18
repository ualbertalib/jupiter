require 'test_helper'

class ItemTest < ActiveSupport::TestCase

  test 'there is no default visibility' do
    item = Item.new_locked_ldp_object

    assert_nil item.visibility
  end

  test 'unknown visibilities are not valid' do
    item = Item.new_locked_ldp_object

    item.unlock_and_fetch_ldp_object do |unlocked_item|
      unlocked_item.visibility = 'some_fake_visibility'
    end

    assert_not item.valid?
    assert item.errors[:visibility].present?
    assert_includes item.errors[:visibility], 'some_fake_visibility is not a known visibility'
  end

  test 'embargo is a valid visibility for items' do
    assert_includes Item.valid_visibilities, 'embargo'
  end

  test 'embargo_end_date must be present if visibility is embargo' do
    item = Item.new_locked_ldp_object
    item.unlock_and_fetch_ldp_object do |unlocked_item|
      unlocked_item.visibility = Item::VISIBILITY_EMBARGO
    end

    assert_not item.valid?
    assert item.errors[:embargo_end_date].present?
    assert_includes item.errors[:embargo_end_date], "can't be blank"
  end

  test 'embargo_end_date must be blank for non-embargo visibilities' do
    item = Item.new_locked_ldp_object
    item.unlock_and_fetch_ldp_object do |unlocked_item|
      unlocked_item.visibility = JupiterCore::VISIBILITY_PUBLIC
      unlocked_item.embargo_end_date = '1992-02-01'
    end

    assert_not item.valid?
    assert item.errors[:embargo_end_date].present?
    assert_includes item.errors[:embargo_end_date], 'must be blank'

    refute item.errors[:visibility].present?
  end

  test '#add_to_path assigns paths properly' do
    item = Item.new_locked_ldp_object
    community_id = generate_random_string
    collection_id = generate_random_string

    item.unlock_and_fetch_ldp_object do |unlocked_item|
      unlocked_item.add_to_path(community_id, collection_id)
    end

    assert_includes item.member_of_paths, "#{community_id}/#{collection_id}"
  end

  test 'member_of_paths is not a display attribute' do
    assert_not_includes Item.display_attribute_names, :member_of_paths
  end

end
