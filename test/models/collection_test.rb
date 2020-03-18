require 'test_helper'

class CollectionTest < ActiveSupport::TestCase

  test 'a valid collection can be constructed' do
    community = Community.create!(title: 'Community', owner_id: users(:admin).id)
    collection = Collection.new(title: 'foo', owner_id: users(:regular).id,
                                community_id: community.id)
    assert collection.valid?

    community.destroy
  end

  test 'needs title' do
    collection = Collection.new(owner_id: users(:admin).id)
    assert_not collection.valid?
    assert_equal "Title can't be blank", collection.errors.full_messages.first
  end

  test 'visibility callback' do
    collection = Collection.new(title: 'foo', owner_id: users(:regular).id)
    collection.valid?
    assert_equal collection.visibility, JupiterCore::VISIBILITY_PUBLIC
  end

  test 'a community_id must be present' do
    collection = Collection.new(title: 'foo', owner_id: users(:regular).id)

    assert_not collection.valid?
    assert_includes collection.errors[:community_id], "can't be blank"
  end

  test 'community must exist' do
    community_id = UUIDTools::UUID.random_create
    collection = Collection.new(title: 'foo', owner_id: users(:regular).id)
    # assign this separately in order to bypass the initial Solr document generation, which would otherwise
    # raise an exception about the non-existent Community
    collection.tap { |uo| uo.community_id = community_id }

    assert_not collection.valid?
    assert_includes collection.errors[:community_id],
                    I18n.t('activerecord.errors.models.collection.attributes.community_id.community_not_found',
                           id: community_id)
  end

end
