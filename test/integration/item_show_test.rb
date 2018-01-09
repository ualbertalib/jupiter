require 'test_helper'

class ItemShowTest < ActionDispatch::IntegrationTest

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
    @item1 = Item.new_locked_ldp_object.unlock_and_fetch_ldp_object do |uo|
      uo.title = 'Fantastic item'
      uo.owner = 1
      uo.creators = ['Joe Blow']
      uo.visibility = JupiterCore::VISIBILITY_PUBLIC
      uo.languages = [CONTROLLED_VOCABULARIES[:language].english]
      uo.license = CONTROLLED_VOCABULARIES[:license].attribution_4_0_international
      uo.item_type = CONTROLLED_VOCABULARIES[:item_type].article
      uo.publication_status = CONTROLLED_VOCABULARIES[:publication_status].draft
      uo.subject = ['Items']
      uo.add_to_path(@community1.id, @collection1.id)
      uo.add_to_path(@community1.id, @collection2.id)
      uo.save!
    end
  end

  test 'visiting the show page for an item with two collections as an admin' do
    user = users(:admin)
    sign_in_as user
    get item_url(@item1)

    # Shows two sets of paths to the two collections
    # Both collections are in same community
    assert_select 'div.card-body li.list-group-item a[href=?]', community_path(@community1),
                  text: @community1.title, count: 2
    assert_select 'div.card-body li.list-group-item a[href=?]',
                  community_collection_path(@community1, @collection1),
                  text: @collection1.title, count: 1
    assert_select 'div.card-body li.list-group-item a[href=?]',
                  community_collection_path(@community1, @collection2),
                  text: @collection2.title, count: 1
  end

end
