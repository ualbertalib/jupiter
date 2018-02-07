require 'application_system_test_case'

class ItemShowTest < ApplicationSystemTestCase

  def before_all
    super
    @user = User.find_by(email: 'john_snow@example.com')
    @community = Community.new_locked_ldp_object(title: 'Fancy Community', owner: 1)
                          .unlock_and_fetch_ldp_object(&:save!)
    @collection = Collection.new_locked_ldp_object(community_id: @community.id,
                                                   title: 'Fancy Collection', owner: 1)
                            .unlock_and_fetch_ldp_object(&:save!)

    file1 = File.open(Rails.root + 'app/assets/images/era-logo.png', 'r')
    file2 = File.open(Rails.root + 'app/assets/images/ualib-logo.png', 'r')
    # Half items have 'Fancy' in title, others have 'Nice', distributed between the two collections
    @item = Item.new_locked_ldp_object(visibility: JupiterCore::VISIBILITY_PUBLIC,
                                       owner: @user.id, title: 'Fancy Item',
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
      uo.add_files([file1, file2])
    end
    file1.close
    file2.close
  end

  should 'be able to download files' do
    visit item_path @item
    assert_selector '.js-download', count: 2
    assert_selector '.js-download-all'
    # TODO: test that the files are downloaded via js successfully without making the suite brittle
  end

end
