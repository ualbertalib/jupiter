require 'test_helper'

class Admin::ItemsControllerTest < ActionDispatch::IntegrationTest

  def setup
    @community = Community.new_locked_ldp_object(title: 'Desolate community',
                                                 owner: 1)
    @community.unlock_and_fetch_ldp_object(&:save!)
    @collection = Collection.new_locked_ldp_object(community_id: @community.id,
                                                   title: 'Desolate collection',
                                                   owner: 1)
    @collection.unlock_and_fetch_ldp_object(&:save!)

    @item = Item.new_locked_ldp_object(
      title: 'item for deletion',
      owner: 1,
      creators: ['Joe Blow'],
      created: '1972-08-08',
      languages: [CONTROLLED_VOCABULARIES[:language].english],
      license: CONTROLLED_VOCABULARIES[:license].attribution_4_0_international,
      visibility: JupiterCore::VISIBILITY_PUBLIC,
      item_type: CONTROLLED_VOCABULARIES[:item_type].article,
      publication_status: [CONTROLLED_VOCABULARIES[:publication_status].published],
      subject: ['Deletion']
    ).unlock_and_fetch_ldp_object do |unlocked_item|
      unlocked_item.add_to_path(@community.id, @collection.id)
      unlocked_item.save!
    end
    Sidekiq::Testing.inline! do
      File.open(file_fixture('pdf-sample.pdf'), 'r') do |file|
        @item.add_and_ingest_files([file])
      end
    end
    @item.doi_state # ensure there is a doi to test deletion of
    @item.set_thumbnail(@item.files.first) # ensure there is a thumbnail to test deletion of

    @admin = users(:admin)
    sign_in_as @admin
  end

  test 'should destroy item and its derivatives' do
    # TODO: 'ActiveStorage::Attachment.count' || 'ActiveStorage::Blob.count'
    # wish I could test the thumbnail deletion but flaky on travis-ci
    assert_difference(['Item.count', 'ItemDoiState.count'], -1) do
      delete admin_item_url(@item)
    end

    assert_redirected_to root_path
    assert_equal I18n.t('admin.items.destroy.deleted'), flash[:notice]
  end

  # TODO: test 'should fail gracefully' but punted on stub/mocking raising an error

end
