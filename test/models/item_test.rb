require 'test_helper'

class ItemTest < ActiveSupport::TestCase

  test 'a valid item can be constructed' do
    community = Community.new_locked_ldp_object(title: 'Community', owner: 1, visibility: 'public')
    community.unlock_and_fetch_ldp_object(&:save!)
    collection = Collection.new_locked_ldp_object(title: 'Collection', owner: 1, visibility: 'public',
                                                  community_id: community.id)
    collection.unlock_and_fetch_ldp_object(&:save!)
    item = Item.new_locked_ldp_object(title: 'Item', owner: 1, visibility: 'public',
                                      language: ['http://id.loc.gov/vocabulary/iso639-2/eng'],
                                      license: 'http://creativecommons.org/licenses/by/4.0/')
    item.unlock_and_fetch_ldp_object do |unlocked_item|
      unlocked_item.add_to_path(community.id, collection.id)
      unlocked_item.save!
    end
    assert item.valid?
  end

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

  test 'a community/collection path must be present' do
    item = Item.new_locked_ldp_object

    assert_not item.valid?
    assert_includes item.errors[:member_of_paths], "can't be blank"
  end

  test 'community/collection must exist' do
    item = Item.new_locked_ldp_object
    community_id = generate_random_string
    collection_id = generate_random_string
    item.unlock_and_fetch_ldp_object do |unlocked|
      unlocked.add_to_path(community_id, collection_id)
    end

    assert_not item.valid?
    assert_includes item.errors[:member_of_paths],
                    I18n.t('activemodel.errors.models.ir_item.attributes.member_of_paths.community_not_found',
                           id: community_id)
    assert_includes item.errors[:member_of_paths],
                    I18n.t('activemodel.errors.models.ir_item.attributes.member_of_paths.collection_not_found',
                           id: collection_id)
  end

  test 'a language must be present' do
    item = Item.new_locked_ldp_object

    assert_not item.valid?
    assert_includes item.errors[:language], "can't be blank"
  end

  test 'a language must be from the controlled vocabulary' do
    item = Item.new_locked_ldp_object(language: ['whatever'])
    assert_not item.valid?
    assert_includes item.errors[:language], 'is not recognized'

    item = Item.new_locked_ldp_object(language: ['http://id.loc.gov/vocabulary/iso639-2/eng'])
    assert_not item.valid?
    refute_includes item.errors.keys, :language
  end

  test 'a license must be present' do
    item = Item.new_locked_ldp_object

    assert_not item.valid?
    assert_includes item.errors[:license], "can't be blank"
  end

  test 'a license must be from the controlled vocabulary' do
    item = Item.new_locked_ldp_object(license: 'whatever')
    assert_not item.valid?
    assert_includes item.errors[:license], 'is not recognized'

    item = Item.new_locked_ldp_object(license: 'http://creativecommons.org/licenses/by/4.0/')
    assert_not item.valid?
    refute_includes item.errors.keys, :license
  end

end
