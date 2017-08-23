require 'test_helper'

class CommunityShowTest < ActionDispatch::IntegrationTest

  setup do
    admin = users(:admin_user)

    # TODO: setup proper fixtures for LockedLdpObjects

    # A community with two collections
    @community1 = Community.new_locked_ldp_object(title: 'Two collection community',
                                                  owner: admin.id)
    @community1.unlock_and_fetch_ldp_object(&:save!)
    @collection1 = Collection.new_locked_ldp_object(community_id: @community1.id,
                                                    title: 'Nice collection',
                                                    owner: admin.id)
    @collection1.unlock_and_fetch_ldp_object(&:save!)
    @collection2 = Collection.new_locked_ldp_object(community_id: @community1.id,
                                                    title: 'Another collection',
                                                    owner: admin.id)
    @collection2.unlock_and_fetch_ldp_object(&:save!)

    # A community with no collections
    @community2 = Community.new_locked_ldp_object(title: 'Empty community',
                                                  owner: admin.id)
    @community2.unlock_and_fetch_ldp_object(&:save!)
  end

  teardown do
    ActiveFedora::Cleaner.clean!
  end

  test 'visiting the show page for a community with two collections as an admin' do
    user = users(:admin)
    sign_in_as user
    get community_url(@community1)

    # Community delete and edit should be shown
    test_admin_links(true)

    # Links to collections should be shown
    test_collections_header(true)
    test_no_collections_message(false)
    test_collection_links(true)
  end

  test 'visiting the show page for a community with two collections as a regular user' do
    user = users(:regular_user)
    sign_in_as user
    get community_url(@community1)

    # Community delete and edit should not be shown
    test_admin_links(false)

    # Links to collections should be shown
    test_collections_header(true)
    test_no_collections_message(false)
    test_collection_links(true)
  end

  test 'visiting a community with no collections' do
    user = users(:admin)
    sign_in_as user
    get community_url(@community2)

    # Links to collections should no be shown
    test_collections_header(false)
    test_no_collections_message(true)
    test_collection_links(false)
  end

  private

  def test_admin_links(true_false)
    count = true_false ? 1 : 0
    assert_select 'a[href=?]', community_path(@community1),
                  text: 'Delete', count: count
    assert_select 'a[href=?]', edit_community_path(@community1),
                  text: 'Edit', count: count
    assert_select 'a[href=?]', new_community_collection_path(@community1),
                  text: 'Add Collection', count: count
  end

  def test_collections_header(true_false)
    assert_select 'h4.collections-header',
                  text: 'Collections in this Community', count: true_false ? 1 : 0
  end

  def test_no_collections_message(true_false)
    assert_select 'h4.collections-header',
                  text: 'There are no Collections in this Community',
                  count: true_false ? 1 : 0
  end

  def test_collection_links(true_false)
    assert_select 'div.list-group', true_false do
      assert_select 'a[href=?]',
                    community_collection_path(@community1, @collection1),
                    text: @collection1.title
      assert_select 'a[href=?]', community_collection_path(@community1, @collection2),
                    text: @collection2.title
    end
  end

end
