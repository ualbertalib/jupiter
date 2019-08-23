require 'application_system_test_case'

class ItemShowTest < ApplicationSystemTestCase

  def before_all
    super
    @user = User.find_by(email: 'john_snow@example.com')

    @community = locked_ldp_fixture(Community, :fancy).unlock_and_fetch_ldp_object(&:save!)
    @collection = locked_ldp_fixture(Collection, :fancy).unlock_and_fetch_ldp_object(&:save!)

    # Half items have 'Fancy' in title, others have 'Nice', distributed between the two collections
    @item = Item.new(visibility: JupiterCore::VISIBILITY_PUBLIC,
                                        owner_id: 1, title: 'Fancy Item',
                                        creators: ['Joe Blow'],
                                        created: '1938-01-02',
                                        languages: [CONTROLLED_VOCABULARIES[:language].english],
                                        license: CONTROLLED_VOCABULARIES[:license].attribution_4_0_international,
                                        item_type: CONTROLLED_VOCABULARIES[:item_type].article,
                                        publication_status: [CONTROLLED_VOCABULARIES[:publication_status].published],
                                        subject: ['Items']).unlock_and_fetch_ldp_object do |uo|
      uo.add_to_path(@community.id, @collection.id)
      uo.add_to_path(@community.id, @collection.id)
      uo.save!
    end
    Sidekiq::Testing.inline! do
      # Attach multiple files to the mondo-item
      File.open(Rails.root + 'app/assets/images/era-logo.png', 'r') do |file1|
        File.open(Rails.root + 'app/assets/images/ualib-logo.png', 'r') do |file2|
          @item.add_and_ingest_files([file1, file2])
        end
      end
    end

    @item2 = Item.new(visibility: JupiterCore::VISIBILITY_AUTHENTICATED,
                                        owner_id: @user.id, title: 'CCID Item',
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

    @thesis = Thesis.new(
      title: 'Thesis about the effects of missing regression tests',
      graduation_date: 'Fall 1990',
      dissertant: 'Joe Blow',
      abstract: generate_random_string,
      language: CONTROLLED_VOCABULARIES[:language].english,
      specialization: 'Failure Analysis',
      departments: ["Deparment of Makin' Computers Compute"],
      supervisors: ['Alan Turing (Department of Mathematics)'],
      committee_members: ['Alonzo Church (Department of Mathematics)'],
      rights: 'Share my stuff with everybody',
      thesis_level: 'Doctorate',
      degree: "Doctorate of Failin' Hard or Hardly Failin'",
      institution: CONTROLLED_VOCABULARIES[:institution].uofa,
      visibility: JupiterCore::VISIBILITY_PUBLIC,
      owner_id: @user.id
    ).unlock_and_fetch_ldp_object do |uo|
      uo.add_to_path(@community.id, @collection.id)
      uo.add_to_path(@community.id, @collection.id)
      uo.save!
    end
  end

  test 'unauthed users should be able to download all files from a public item' do
    visit item_path @item
    assert_selector '.js-download', count: 2
    assert_selector '.js-download-all'
    # TODO: test that the files are downloaded via js successfully without making the suite brittle
  end

  test 'Search faceting on item values is not broken' do
    visit item_path @item
    click_link 'Joe Blow'
    assert_selector "a[href='/search?tab=item']", count: 1
  end

  test 'Visiting authenticated items as an unauthenticated user works' do
    visit item_path @item2
    assert_selector 'h1', text: 'CCID Item', count: 1
  end

  test 'Theses are working correctly' do
    visit item_path @thesis

    assert_selector 'h1', text: 'Thesis about the effects of missing regression tests', count: 1
    assert_selector 'dt', text: 'Type of Item', count: 1
    assert_selector 'dd a', text: 'Thesis', count: 1
  end

  test 'Item statistics are present' do
    visit item_path @thesis
    assert_selector "div[class='card-header']", text: 'Usage', count: 1
    assert_selector 'div ul li', text: 'No download information available'
  end

end
