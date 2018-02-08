require 'application_system_test_case'

class ItemShowTest < ApplicationSystemTestCase

  def before_all
    super
    @community = Community.new_locked_ldp_object(title: 'Fancy Community', owner: 1)
                          .unlock_and_fetch_ldp_object(&:save!)
    @collection = Collection.new_locked_ldp_object(community_id: @community.id,
                                                   title: 'Fancy Collection', owner: 1)
                            .unlock_and_fetch_ldp_object(&:save!)

    # Half items have 'Fancy' in title, others have 'Nice', distributed between the two collections
    @item1 = Item.new_locked_ldp_object(visibility: JupiterCore::VISIBILITY_PUBLIC,
                                        owner: users(:regular).id, title: 'Fancy Item',
                                        creators: ['Joe Blow'],
                                        created: '2011-11-11',
                                        languages: [CONTROLLED_VOCABULARIES[:language].english],
                                        license: CONTROLLED_VOCABULARIES[:license].attribution_4_0_international,
                                        item_type: CONTROLLED_VOCABULARIES[:item_type].article,
                                        publication_status: [CONTROLLED_VOCABULARIES[:publication_status].published],
                                        subject: ['Fancy things'])
                 .unlock_and_fetch_ldp_object do |uo|
      uo.add_to_path(@community.id, @collection.id)
      uo.add_to_path(@community.id, @collection.id)
      uo.save!
      # Attach multiple files to the mondo-item
      File.open(Rails.root + 'app/assets/images/era-logo.png', 'r') do |file1|
        File.open(Rails.root + 'app/assets/images/ualib-logo.png', 'r') do |file2|
          uo.add_files([file1, file2])
        end
      end
    end
    @item2 = Item.new_locked_ldp_object(visibility: JupiterCore::VISIBILITY_AUTHENTICATED,
                                        owner: users(:regular).id, title: 'CCID Item',
                                        creators: ['Joe Blow'],
                                        created: '2011-11-11',
                                        languages: [CONTROLLED_VOCABULARIES[:language].english],
                                        license: CONTROLLED_VOCABULARIES[:license].attribution_4_0_international,
                                        item_type: CONTROLLED_VOCABULARIES[:item_type].article,
                                        publication_status: [CONTROLLED_VOCABULARIES[:publication_status].published],
                                        subject: ['Fancy things'])
                 .unlock_and_fetch_ldp_object do |uo|
      uo.add_to_path(@community.id, @collection.id)
      uo.add_to_path(@community.id, @collection.id)
      uo.save!
    end
  end

  test 'be able to download files' do
    visit item_path @item1
    assert_selector '.js-download', count: 2
    assert_selector '.js-download-all'
    # TODO: test that the files are downloaded via js successfully without making the suite brittle
  end

  test 'Search faceting on item values is not broken' do
    visit item_path @item1
    click_link 'Joe Blow'
    assert_selector "[href='/search?tab=item']", count: 1
  end

  test 'Visiting authenticated items as an unauthenticated user works' do
    visit item_path @item2
    assert_selector 'h1', text: 'CCID Item', count: 1
  end

end
