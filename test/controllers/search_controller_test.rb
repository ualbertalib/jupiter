require 'test_helper'

class SearchControllerTest < ActionDispatch::IntegrationTest

  def before_all
    super
    @community = Community.new_locked_ldp_object(title: 'Community',
                                                 owner: 1)
    @community.unlock_and_fetch_ldp_object(&:save!)
    @collection = Collection.new_locked_ldp_object(community_id: @community.id,
                                                   title: 'Collection', owner: 1).unlock_and_fetch_ldp_object(&:save!)

    @item1 = Item.new_locked_ldp_object(visibility: JupiterCore::VISIBILITY_PUBLIC,
                                        owner: 1, title: 'Ant',
                                        creators: ['Joe Blow'],
                                        created: '1000000 BC',
                                        languages: [CONTROLLED_VOCABULARIES[:language].english],
                                        item_type: CONTROLLED_VOCABULARIES[:item_type].article,
                                        publication_status: [CONTROLLED_VOCABULARIES[:publication_status].published],
                                        license: CONTROLLED_VOCABULARIES[:license].attribution_4_0_international,
                                        subject: ['Items']).unlock_and_fetch_ldp_object do |uo|
      uo.add_to_path(@community.id, @collection.id)
      uo.save!
    end

    @item2 = Item.new_locked_ldp_object(visibility: JupiterCore::VISIBILITY_PUBLIC,
                                        owner: 1, title: 'Moose',
                                        creators: ['Joe Blow'],
                                        created: '1000000 BC',
                                        languages: [CONTROLLED_VOCABULARIES[:language].english],
                                        item_type: CONTROLLED_VOCABULARIES[:item_type].article,
                                        publication_status: [CONTROLLED_VOCABULARIES[:publication_status].published],
                                        license: CONTROLLED_VOCABULARIES[:license].attribution_4_0_international,
                                        subject: ['Items']).unlock_and_fetch_ldp_object do |uo|
      uo.add_to_path(@community.id, @collection.id)
      uo.save!
    end

    @item3 = Item.new_locked_ldp_object(visibility: JupiterCore::VISIBILITY_PUBLIC,
                                        owner: 1, title: 'Zebra',
                                        creators: ['Joe Blow'],
                                        created: '1000000 BC',
                                        languages: [CONTROLLED_VOCABULARIES[:language].english],
                                        item_type: CONTROLLED_VOCABULARIES[:item_type].article,
                                        publication_status: [CONTROLLED_VOCABULARIES[:publication_status].published],
                                        license: CONTROLLED_VOCABULARIES[:license].attribution_4_0_international,
                                        subject: ['Items']).unlock_and_fetch_ldp_object do |uo|
      uo.add_to_path(@community.id, @collection.id)
      uo.save!
    end

    @item4 = Item.new_locked_ldp_object(visibility: JupiterCore::VISIBILITY_PUBLIC,
                                        owner: 1, title: 'Ant Moose',
                                        creators: ['Joe Blow'],
                                        created: '1000000 BC',
                                        languages: [CONTROLLED_VOCABULARIES[:language].english],
                                        item_type: CONTROLLED_VOCABULARIES[:item_type].article,
                                        publication_status: [CONTROLLED_VOCABULARIES[:publication_status].published],
                                        license: CONTROLLED_VOCABULARIES[:license].attribution_4_0_international,
                                        subject: ['Items']).unlock_and_fetch_ldp_object do |uo|
      uo.add_to_path(@community.id, @collection.id)
      uo.save!
    end

    @item5 = Item.new_locked_ldp_object(visibility: JupiterCore::VISIBILITY_PUBLIC,
                                        owner: 1, title: 'Moose Ant',
                                        creators: ['Joe Blow'],
                                        created: '1000000 BC',
                                        languages: [CONTROLLED_VOCABULARIES[:language].english],
                                        item_type: CONTROLLED_VOCABULARIES[:item_type].article,
                                        publication_status: [CONTROLLED_VOCABULARIES[:publication_status].published],
                                        license: CONTROLLED_VOCABULARIES[:license].attribution_4_0_international,
                                        subject: ['Items']).unlock_and_fetch_ldp_object do |uo|
      uo.add_to_path(@community.id, @collection.id)
      uo.save!
    end
  end

  test 'should get results in alphabetical order when no query present' do
    get search_url, as: :json
    assert_response :success
    data = JSON.parse(response.body)
    assert_equal([@item1.id, @item4.id, @item2.id, @item5.id, @item3.id], data.map { |result| result['id'] })
  end

  test 'should get results in relevance order when a query is present' do
    get search_url, as: :json, params: { search: 'Moose' }
    assert_response :success
    data = JSON.parse(response.body)
    assert_equal([@item2.id, @item5.id, @item4.id], data.map { |result| result['id'] })
  end

  test 'should work when asking for HTML results too' do
    get search_url, params: { search: 'Moose' }
    assert_response :success

    [@item2, @item5, @item4].each do |expected_result|
      assert_match(/<a href="\/items\/#{expected_result.id}">/, response.body)
    end
  end

end
