require 'test_helper'

class CollectionTest < ActiveSupport::TestCase

  test 'a valid collection can be constructed' do
    community = communities(:community_books)
    collection = Collection.new(title: 'foo', owner_id: users(:user_regular).id,
                                community_id: community.id)

    assert_predicate collection, :valid?
  end

  test 'needs title' do
    collection = Collection.new(owner_id: users(:user_admin).id)

    assert_not collection.valid?
    assert_equal "Title can't be blank", collection.errors.full_messages.first
  end

  test 'visibility callback' do
    collection = Collection.new(title: 'foo', owner_id: users(:user_regular).id)
    collection.valid?

    assert_equal collection.visibility, JupiterCore::VISIBILITY_PUBLIC
  end

  test 'a community must be present' do
    collection = Collection.new(title: 'foo', owner_id: users(:user_regular).id)

    assert_not collection.valid?
    assert_includes collection.errors[:community], 'must exist'
  end

  test 'community must exist' do
    community_id = UUIDTools::UUID.random_create
    collection = Collection.new(title: 'foo', owner_id: users(:user_regular).id)
    # assign this separately in order to bypass the initial Solr document generation, which would otherwise
    # raise an exception about the non-existent Community
    collection.tap { |uo| uo.community_id = community_id }

    assert_not collection.valid?
    assert_includes collection.errors[:community_id],
                    I18n.t('activerecord.errors.models.collection.attributes.community_id.community_not_found',
                           id: community_id)
  end

  test 'after_save read_only callback' do
    collection = collections(:collection_fancy)
    item = items(:item_fancy)

    assert_not item.read_only?

    collection.read_only = true
    collection.save!

    item.reload

    assert_predicate item, :read_only?
  end

  test 'should not set read only to false if object belongs to other read_only collections' do
    collection1 = collections(:collection_read_only)
    collection2 = collections(:collection_another_read_only)
    item = items(:item_fancy)

    # Add the item to both collections
    item.add_to_path(collection1.community_id, collection1.id)
    item.add_to_path(collection2.community_id, collection2.id)
    item.read_only = true
    item.save!

    # Attempt to set read_only to false in one collection
    collection1.update(read_only: false)

    # Ensure the item's read_only remains true because of the other collection
    assert item.reload.read_only
  end

end
