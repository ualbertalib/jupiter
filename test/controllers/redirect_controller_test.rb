require 'test_helper'

class RedirectControllerTest < ActionDispatch::IntegrationTest

  def before_all
    super
    @community = Community.new_locked_ldp_object(title: 'Fancy Community', owner: 1,
                                                 fedora3_uuid: 'uuid:community', hydra_noid: 'community-noid')
                          .unlock_and_fetch_ldp_object(&:save!)
    @collection = Collection.new_locked_ldp_object(community_id: @community.id,
                                                   title: 'Fancy Collection', owner: 1,
                                                   fedora3_uuid: 'uuid:collection', hydra_noid: 'collection-noid')
                            .unlock_and_fetch_ldp_object(&:save!)
    @filename = 'pdf-sample.pdf'
    @item = Item.new_locked_ldp_object(visibility: JupiterCore::VISIBILITY_PUBLIC,
                                       owner: 1, title: 'Fancy Item',
                                       creators: ['Joe Blow'],
                                       created: '1950',
                                       languages: [CONTROLLED_VOCABULARIES[:language].english],
                                       item_type: CONTROLLED_VOCABULARIES[:item_type].article,
                                       publication_status: [CONTROLLED_VOCABULARIES[:publication_status].published],
                                       license: CONTROLLED_VOCABULARIES[:license].attribution_4_0_international,
                                       subject: ['Items'],
                                       fedora3_uuid: 'uuid:item',
                                       hydra_noid: 'item-noid')
                .unlock_and_fetch_ldp_object do |uo|
      uo.add_to_path(@community.id, @collection.id)

      File.open(file_fixture(@filename), 'r') do |file|
        uo.add_files([file])
      end
      uo.save!
    end
    @file_set_id = @item.file_sets.first.id
  end

  test 'should redirect ancient Fedora3 items' do
    get '/public/view/item/uuid:item'
    assert_response :moved_permanently
    assert_redirected_to item_url(@item)
  end

  test 'should 404 on missing ancient Fedora3 items' do
    get '/public/view/item/uuid:whatever'
    assert_response :not_found
  end

  test 'should redirect ancient Fedora3 community' do
    get '/public/view/community/uuid:community'
    assert_response :moved_permanently
    assert_redirected_to community_url(@community)
  end

  test 'should 404 on missing ancient Fedora3 community' do
    get '/public/view/community/uuid:whatever'
    assert_response :not_found
  end

  test 'should redirect ancient Fedora3 collection' do
    get '/public/view/collection/uuid:collection'
    assert_response :moved_permanently
    assert_redirected_to community_collection_url(@community, @collection)
  end

  test 'should 404 on missing ancient Fedora3 collection' do
    get '/public/view/collection/uuid:whatever'
    assert_response :not_found
  end

  test 'should redirect ancient Fedora3 datastream' do
    get '/public/view/item/uuid:item'
    assert_response :moved_permanently
    assert_redirected_to item_url(@item)
  end

  test 'should redirect old HydraNorth items' do
    get '/files/item-noid'
    assert_response :moved_permanently
    assert_redirected_to item_url(@item)
  end

  test 'should 404 on old missing HydraNorth items' do
    get '/files/not-a-item-noid'
    assert_response :not_found
  end

  test 'should redirect old HydraNorth file downloads' do
    get '/files/item-noid/pdf-sample.pdf'
    assert_response :moved_permanently
    assert_redirected_to url_for(controller: :file_sets,
                                 action: :show,
                                 id: @item.id,
                                 file_set_id: @file_set_id,
                                 file_name: @filename)
  end

  test 'should redirect missing old HydraNorth file downloads to the item' do
    get '/files/item-noid/not-a-pdf-sample.pdf'
    assert_response :found
    assert_redirected_to item_url(@item)
  end

  test 'should 404 a file download for a missing item' do
    get '/files/not-a-item-noid/pdf-sample.pdf'
    assert_response :not_found
  end

  test 'should redirect old HydraNorth community' do
    get '/collections/community-noid'
    assert_response :moved_permanently
    assert_redirected_to community_path(@community)
  end

  test 'should redirect old HydraNorth collection' do
    get '/collections/collection-noid'
    assert_response :moved_permanently
    assert_redirected_to community_collection_path(@community, @collection)
  end

  test 'should 404 for missing old HydraNorth communities/collections' do
    get '/collections/no-community-or-collection-noid'
    assert_response :not_found
  end

  test 'should 410 on ancient thesis deposit URL' do
    get '/action/submit/init/thesis/uuid:7af76c0f-61d6-4ebc-a2aa-79c125480269'
    assert_response :gone
  end

  test 'should 410 on ancient author URL' do
    get '/public/view/author/someguy'
    assert_response :gone
  end

end
