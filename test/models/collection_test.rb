require 'test_helper'

class CollectionTest < ActiveSupport::TestCase

  test 'a valid collection can be constructed' do
    community = Community.new_locked_ldp_object(title: 'Community', owner: 1).unlock_and_fetch_ldp_object(&:save!)
    collection = Collection.new_locked_ldp_object(title: 'foo', owner: users(:regular_user).id,
                                                  community_id: community.id)
    assert collection.valid?
  end

  test 'needs title' do
    collection = Collection.new_locked_ldp_object(owner: users(:admin).id)
    refute collection.valid?
    assert_equal "Title can't be blank", collection.errors.full_messages.first
  end

  test 'visibility callback' do
    collection = Collection.new_locked_ldp_object(title: 'foo', owner: users(:regular_user).id)
    collection.valid?
    assert_equal collection.visibility, JupiterCore::VISIBILITY_PUBLIC
  end

  test 'a community_id must be present' do
    collection = Collection.new_locked_ldp_object(title: 'foo', owner: users(:regular_user).id)

    assert_not collection.valid?
    assert_includes collection.errors[:community_id], "can't be blank"
  end

  test 'community must exist' do
    community_id = generate_random_string
    collection = Collection.new_locked_ldp_object(title: 'foo', owner: users(:regular_user).id,
                                                  community_id: community_id)

    assert_not collection.valid?
    assert_includes collection.errors[:community_id],
                    I18n.t('activemodel.errors.models.ir_collection.attributes.community_id.community_not_found',
                           id: community_id)
  end

end
