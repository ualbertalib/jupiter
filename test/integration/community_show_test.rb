require 'test_helper'

# TODO: This test would be better as an System Acceptance test instead?
class CommunityShowTest < ActionDispatch::IntegrationTest

  def before_all
    super

    # TODO: setup proper fixtures for LockedLdpObjects
    # A community with two collections
    @community1 = Community
                  .new_locked_ldp_object(title: 'Two collection community', owner: 1)
                  .unlock_and_fetch_ldp_object(&:save!)
    @collection1 = Collection
                   .new_locked_ldp_object(community_id: @community1.id,
                                          title: 'Nice collection', owner: 1)
                   .unlock_and_fetch_ldp_object(&:save!)
    @collection2 = Collection
                   .new_locked_ldp_object(community_id: @community1.id,
                                          title: 'Another collection', owner: 1)
                   .unlock_and_fetch_ldp_object(&:save!)

    # A community with no collections
    @community2 = Community
                  .new_locked_ldp_object(title: 'Empty community', owner: 1)
                  .unlock_and_fetch_ldp_object(&:save!)
  end

  test 'visiting the show page for a community with two collections as an admin' do
    admin = users(:admin)
    sign_in_as admin
    get community_url(@community1)

    # Community delete, edit and create new collection buttons should be shown
    assert_select 'a[href=?]',
                  community_path(@community1),
                  text: I18n.t('delete')

    assert_select 'a[href=?]',
                  edit_community_path(@community1),
                  text: I18n.t('edit')

    assert_select 'a[href=?]',
                  new_community_collection_path(@community1),
                  text: I18n.t('communities.show.create_new_collection')

    # Should show 2 collections with a heading
    assert_select 'h4.collections-header', text: I18n.t('communities.show.collections_list_header')
    assert_select 'ul.list-group li', count: 2

    # Collections should have a linkable title and edit/delete buttons
    assert_select 'ul.list-group li.list-group-item a[href=?]',
                  community_collection_path(@community1, @collection1),
                  text: @collection1.title
    assert_select "a[href='#{edit_community_collection_path(@community1, @collection1)}']"\
                  '.edit-collection',
                  text: I18n.t('edit')
    assert_select "a[href='#{community_collection_path(@community1, @collection1)}']"\
                  '.delete-collection',
                  text: I18n.t('delete')
  end

  test 'visiting the show page for a community with two collections as a regular user' do
    user = users(:regular_user)
    sign_in_as user
    get community_url(@community1)

    # Community delete, edit and create new collection buttons should not be shown
    assert_select 'a[href=?]',
                  community_path(@community1),
                  false

    assert_select 'a[href=?]',
                  edit_community_path(@community1),
                  false

    assert_select 'a[href=?]',
                  new_community_collection_path(@community1),
                  false

    # Should show 2 collections with a heading
    assert_select 'h4.collections-header', text: I18n.t('communities.show.collections_list_header')
    assert_select 'ul.list-group li', count: 2

    # Collections should have a linkable title but no edit/delete buttons
    assert_select 'ul.list-group li.list-group-item a[href=?]',
                  community_collection_path(@community1, @collection1),
                  text: @collection1.title
    assert_select "a[href='#{edit_community_collection_path(@community1, @collection1)}']"\
                  '.edit-collection',
                  false
    assert_select "a[href='#{community_collection_path(@community1, @collection1)}']"\
                  '.delete-collection',
                  false
  end

  test 'visiting a community with no collections' do
    user = users(:admin)
    sign_in_as user
    get community_url(@community2)

    # Community delete, edit and create new collection buttons should be shown
    assert_select 'a[href=?]',
                  community_path(@community2),
                  text: I18n.t('delete')
    assert_select 'a[href=?]',
                  edit_community_path(@community2),
                  text: I18n.t('edit')

    assert_select 'a[href=?]',
                  new_community_collection_path(@community2),
                  text: I18n.t('communities.show.create_new_collection')

    # No collections should no be shown
    assert_select 'h4.collections-header', text: I18n.t('communities.show.collections_list_header')
    assert_select 'ul.list-group li', count: 1
    assert_select 'ul.list-group li.list-group-item', text: I18n.t('communities.show.no_collections')
  end

end
