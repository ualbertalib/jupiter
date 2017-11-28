require 'test_helper'

# TODO: This test would be better as an System Acceptance test instead?
class CollectionShowTest < ActionDispatch::IntegrationTest

  # TODO: add tests involving non-public items

  def before_all
    super

    # TODO: setup proper fixtures for LockedLdpObjects

    # A community with a collection
    @community = Community.new_locked_ldp_object(title: 'Two collection community', owner: 1)
                          .unlock_and_fetch_ldp_object(&:save!)
    @collection = Collection.new_locked_ldp_object(community_id: @community.id, title: 'Nice collection', owner: 1)
                            .unlock_and_fetch_ldp_object(&:save!)
    @items = (0..1).map do |i|
      Item.new_locked_ldp_object(visibility: JupiterCore::VISIBILITY_PUBLIC,
                                 owner: 1,
                                 language: ['http://id.loc.gov/vocabulary/iso639-2/eng'],
                                 license: 'http://creativecommons.org/licenses/by/4.0/',
                                 title: "Fancy Item #{i}").unlock_and_fetch_ldp_object do |uo|
        uo.add_to_path(@community.id, @collection.id)
        uo.save!
      end
    end
  end

  test 'visiting the show page for a collection as an admin' do
    admin = users(:admin)
    sign_in_as admin
    get community_collection_url(@community, @collection)

    # Breadcrumb
    assert_select 'ol.breadcrumb', count: 1
    assert_select 'li.breadcrumb-item', count: 2
    assert_select 'li.breadcrumb-item a', text: @community.title
    assert_select 'li.breadcrumb-item a', text: @collection.title, count: 0
    assert_select 'li.breadcrumb-item.active', text: @collection.title

    # Edit collection link
    assert_select "a[href='#{edit_admin_community_collection_path(@community, @collection)}']", text: 'Edit'

    # Delete collection link
    delete = css_select "a[href='#{admin_community_collection_path(@community, @collection)}']"
    assert delete.count == 1
    assert delete.first.attributes['data-method'].to_s == 'delete'

    # Items are shown
    assert_select 'div.list-group .list-group-item', count: 2

    # Links to items
    @items.each do |item|
      item_links = css_select "div.list-group .list-group-item a[href='#{item_path(item)}']"
      assert item_links.count == 2
      # Link to item
      assert item_links.first.text == item.title
      # Link to delete item
      assert_match 'Delete', item_links.last.text
      assert item_links.last.attributes['data-method'].to_s == 'delete'

      # Link to edit item
      assert_select "div.list-group .list-group-item a[href='#{edit_item_path(item)}']", text: 'Edit'
    end
  end

  test 'visiting the show page for a collection as a regular user' do
    user = users(:regular_user)
    sign_in_as user
    get community_collection_url(@community, @collection)

    # Breadcrumb
    assert_select 'ol.breadcrumb', count: 1
    assert_select 'li.breadcrumb-item', count: 2
    assert_select 'li.breadcrumb-item a', text: @community.title
    assert_select 'li.breadcrumb-item a', text: @collection.title, count: 0
    assert_select 'li.breadcrumb-item.active', text: @collection.title

    # No edit community link
    assert_select "a[href='#{edit_admin_community_collection_path(@community, @collection)}']",
                  count: 0
    # No delete community link
    assert_select "a[href='#{admin_community_collection_path(@community, @collection)}']",
                  count: 0

    # Items are shown
    assert_select 'div.list-group .list-group-item', count: 2

    # Links to items
    @items.each do |item|
      item_links = css_select "div.list-group .list-group-item a[href='#{item_path(item)}']"
      assert item_links.count == 1
      # Link to item
      assert item_links.first.text == item.title
      # No link to delete item
      assert item_links.first.attributes['data-method'].to_s != 'delete'
      # No link to edit item
      assert_select "div.list-group .list-group-item a[href='#{edit_item_path(item)}']", count: 0
    end
  end

end
