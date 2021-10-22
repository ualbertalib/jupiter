require 'test_helper'

# TODO: This test would be better as an System Acceptance test instead?
class CommunityShowTest < ActionDispatch::IntegrationTest

  setup do
    # A community with two collections and a logo
    @community1 = Community.create!(title: 'Two collection community', owner_id: users(:user_admin).id)
    @collection1 = Collection.create!(community_id: @community1.id,
                                      title: 'Nice collection', owner_id: users(:user_admin).id)
    # A restricted (to deposit, not to view) collection
    @collection2 = Collection.create!(community_id: @community1.id,
                                      restricted: true,
                                      title: 'Another collection', owner_id: users(:user_admin).id)
    @community1.logo.attach io: File.open(file_fixture('image-sample.jpeg')),
                            filename: 'image-sample.jpeg', content_type: 'image/jpeg'

    # A community with no collections
    @community2 = communities(:community_with_no_collections)
  end

  test 'visiting the show page for a community with two collections as an admin' do
    admin = users(:user_admin)
    sign_in_as admin
    get community_url(@community1)

    # Logo should be shown
    assert_select 'img.img-thumbnail', count: 1
    assert_select 'div.img-thumbnail i.fa', count: 0

    # Community delete, edit and create new collection buttons should be shown
    assert_select 'a[href=?]',
                  admin_community_path(@community1),
                  text: I18n.t('delete')

    assert_select 'a[href=?]',
                  edit_admin_community_path(@community1),
                  text: I18n.t('edit')

    assert_select 'a[href=?]',
                  new_admin_community_collection_path(@community1),
                  text: I18n.t('communities.show.create_collection')

    # Should show 2 collections with a heading
    assert_select 'h2', text: I18n.t('communities.show.collections_list_header')
    assert_select 'ul.list-group li', count: 2

    # Collections should have a linkable title and edit/delete buttons
    assert_select 'ul.list-group li.list-group-item a[href=?]',
                  community_collection_path(@community1, @collection1),
                  text: @collection1.title
    assert_select "a[href='#{edit_admin_community_collection_path(@community1, @collection1)}']",
                  text: I18n.t('edit')
    assert_select "a[href='#{admin_community_collection_path(@community1, @collection1)}']",
                  text: I18n.t('delete')
  end

  test 'visiting the show page for a community with two collections and a logo '\
       'as a regular user' do
    user = users(:user_regular)
    sign_in_as user
    get community_url(@community1)

    # Logo should be shown
    assert_select 'img.img-thumbnail', count: 1
    assert_select 'div.img-thumbnail i.fa', count: 0

    # Community delete, edit and create new collection buttons should not be shown
    assert_select 'a[href=?]',
                  admin_community_path(@community1),
                  false

    assert_select 'a[href=?]',
                  edit_admin_community_path(@community1),
                  false

    assert_select 'a[href=?]',
                  new_admin_community_collection_path(@community1),
                  false

    # Should show 2 collections with a heading
    assert_select 'h2', text: I18n.t('communities.show.collections_list_header')
    assert_select 'ul.list-group li.list-group-item', count: 2

    # Collections should have be linkable but no edit/delete buttons should be displayed
    assert_select 'ul.list-group li.list-group-item a[href=?]',
                  community_collection_path(@community1, @collection1),
                  text: @collection1.title
    assert_select "a[href='#{edit_admin_community_collection_path(@community1, @collection1)}']",
                  false
    assert_select "a[href='#{admin_community_collection_path(@community1, @collection1)}']",
                  false
  end

  test 'visiting a community with no collections or logo' do
    user = users(:user_regular)
    sign_in_as user
    get community_url(@community2)

    # Should have fallback image
    assert_select 'img.img-thumbnail:match("src", ?)', /era-logo-without-text/
    assert_select 'div.img-thumbnail i.fa', count: 0

    # No collections should no be shown
    assert_select 'h2', text: I18n.t('communities.show.collections_list_header')
    assert_select 'ul.list-group li', count: 1
    assert_select 'ul.list-group li.list-group-item', text: I18n.t('communities.show.no_collections')
  end

  test "JSON for collections (deposit form AJAX) as regular user doesn't include restricted collection" do
    user = users(:user_regular)
    sign_in_as user
    get community_url(@community1, format: :json)
    body = JSON.parse(response.body)
    assert_equal(1, body['collections'].count)
    assert_includes body['collections'].map { |c| c['id'] }, @collection1.id
  end

  test 'JSON for collections (deposit form AJAX) as admin includes all collections' do
    user = users(:user_admin)
    sign_in_as user
    get community_url(@community1, format: :json)
    body = JSON.parse(response.body)
    assert_equal(2, body['collections'].count)
    assert_includes body['collections'].map { |c| c['id'] }, @collection1.id
    assert_includes body['collections'].map { |c| c['id'] }, @collection2.id
  end

end
