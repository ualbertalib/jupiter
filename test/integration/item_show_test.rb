require 'test_helper'

class ItemShowTest < ActionDispatch::IntegrationTest

  setup do
    @admin = users(:admin)
    # A community with two collections
    @community = communities(:books)
    @collection1 = Collection.create!(community_id: @community.id,
                                      title: 'Nice collection', owner_id: @admin.id)
    @collection2 = Collection.create!(community_id: @community.id,
                                      title: 'Another collection', owner_id: @admin.id)
    @item = Item.new.tap do |uo|
      uo.title = 'Fantastic item'
      uo.owner_id = @admin.id
      uo.creators = ['Joe Blow']
      uo.visibility = JupiterCore::VISIBILITY_PUBLIC
      uo.created = '1999-09-09'
      uo.languages = [CONTROLLED_VOCABULARIES[:language].english]
      uo.license = CONTROLLED_VOCABULARIES[:license].attribution_4_0_international
      uo.item_type = CONTROLLED_VOCABULARIES[:item_type].article
      uo.publication_status = [CONTROLLED_VOCABULARIES[:publication_status].draft,
                               CONTROLLED_VOCABULARIES[:publication_status].submitted]
      uo.subject = ['Items']
      uo.add_to_path(@community.id, @collection1.id)
      uo.add_to_path(@community.id, @collection2.id)
      uo.save!
    end
  end

  test 'visiting the show page for an item with two collections as an admin' do
    sign_in_as @admin
    get item_url(@item)

    # Shows two sets of paths to the two collections
    # Both collections are in same community
    assert_select 'div.card-body li.list-group-item a[href=?]', community_path(@community),
                  text: @community.title, count: 2
    assert_select 'div.card-body li.list-group-item a[href=?]',
                  community_collection_path(@community, @collection1),
                  text: @collection1.title, count: 1
    assert_select 'div.card-body li.list-group-item a[href=?]',
                  community_collection_path(@community, @collection2),
                  text: @collection2.title, count: 1
  end

end
