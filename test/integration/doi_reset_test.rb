require 'test_helper'

class DoiResetTest < ActionDispatch::IntegrationTest

  setup do
    @admin = users(:admin)
    @user = users(:regular)
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

  test 'reset button displays as needed' do
    sign_in_as @admin
    get item_url(@item)

    # Reset DOI doesn't show up because the item was just updated.
    assert_select '.admin-sidebar .btn', text: I18n.t('items.admin_sidebar.reset_doi'), count: 0
    travel 2.minutes do
      get item_url(@item)
      assert_select '.admin-sidebar .btn', text: I18n.t('items.admin_sidebar.reset_doi'), count: 1

      # Doesn't dhow button when logged out or not an admin.
      get logout_url
      get item_url(@item)
      assert_select '.admin-sidebar .btn', text: I18n.t('items.admin_sidebar.reset_doi'), count: 0

      sign_in_as @user
      get item_url(@item)
      assert_select '.admin-sidebar .btn', text: I18n.t('items.admin_sidebar.reset_doi'), count: 0
    end
  end

end
