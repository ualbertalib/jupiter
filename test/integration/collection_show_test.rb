require 'test_helper'

# TODO: This test would be better as an System Acceptance test instead?
class CollectionShowTest < ActionDispatch::IntegrationTest

  # TODO: add tests involving non-public items

  setup do
    @community = communities(:community_fancy)
    @collection = collections(:collection_fancy)
    fancy_item = items(:item_fancy)
    admin_item = items(:item_admin)
    @items = [fancy_item, admin_item]

    @items.each(&:update_solr)
  end

  test 'visiting the show page for a collection as an admin' do
    admin = users(:user_admin)
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
    assert_equal(1, delete.count)
    assert_equal('delete', delete.first.attributes['data-method'].to_s)

    # Items are shown
    assert_select '.jupiter-results ul.list-group .list-group-item', count: 2

    # Links to items
    @items.each do |item|
      item_links = css_select ".jupiter-results ul.list-group .list-group-item a[href='#{item_path(item)}']"

      # Thumbnail, text link, and delete link
      assert_equal(2, item_links.count)
      # Thumbnail link to item
      assert_includes item_links.first.inner_html, 'img-thumbnail'
      # Text link to item
      assert_equal item_links[1].text, item.title

      # Link to delete item
      delete_link = css_select ".jupiter-results ul.list-group .list-group-item a[href='#{admin_item_path(item)}']"
      assert_match 'Delete', delete_link.last.text
      assert_equal('delete', delete_link.last.attributes['data-method'].to_s)

      # Link to edit item
      assert_select "ul.list-group .list-group-item a[href='#{edit_item_path(item)}']", text: 'Edit'
    end
  end

  test 'visiting the show page for a collection as a regular user' do
    user = users(:user_regular_two)
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
    assert_select '.jupiter-results ul.list-group .list-group-item', count: 2

    # Links to items
    @items.each do |item|
      item_links = css_select ".jupiter-results ul.list-group .list-group-item a[href='#{item_path(item)}']"
      # Only thumbnail and text link expected
      assert_equal(2, item_links.count)
      # Thumbnail link to item
      assert_includes item_links.first.inner_html, 'img-thumbnail'
      # Link to item
      assert_equal item_links.last.text, item.title
      # No link to delete item
      assert_not_equal item_links.first.attributes['data-method'].to_s, 'delete'
      assert_not_equal item_links.last.attributes['data-method'].to_s, 'delete'
      # No link to edit item
      assert_select "ul.list-group .list-group-item a[href='#{edit_item_path(item)}']", count: 0
    end
  end

  test 'searching within the collection as a regular user' do
    # TODO: should probably hook this up to a system test that submits the form
    user = users(:user_regular)
    sign_in_as user
    get community_collection_url(@community, @collection, search: 'Fancy')

    # Only 'Fancy' items are shown
    assert_select '.jupiter-results ul.list-group .list-group-item', count: 1
    assert_select '.jupiter-results ul.list-group .list-group-item h3 a', text: 'Fancy Item', count: 1
    assert_select '.jupiter-results ul.list-group .list-group-item h3 a', text: 'Nice Item', count: 0
  end

end
