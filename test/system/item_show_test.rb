require 'application_system_test_case'

class ItemShowTest < ApplicationSystemTestCase

  setup do
    @user = users(:user_regular)
    admin = users(:user_admin)
    @community = communities(:community_books)
    @collection = collections(:collection_fantasy)

    # Half items have 'Fancy' in title, others have 'Nice', distributed between the two collections
    @item = Item.new(visibility: JupiterCore::VISIBILITY_PUBLIC,
                     owner_id: admin.id, title: 'Fancy Item',
                     creators: ['Joe Blow'],
                     created: '1938-01-02',
                     languages: [ControlledVocabulary.era.language.english],
                     license: ControlledVocabulary.era.license.attribution_4_0_international,
                     item_type: ControlledVocabulary.era.item_type.article,
                     publication_status: [ControlledVocabulary.era.publication_status.published],
                     subject: ['Items']).tap do |uo|
      uo.add_to_path(@community.id, @collection.id)
      uo.add_to_path(@community.id, @collection.id)
      uo.save!
    end
    Sidekiq::Testing.inline! do
      # Attach multiple files to the mondo-item
      File.open(file_fixture('image-sample.jpeg'), 'r') do |file1|
        File.open(file_fixture('pdf-sample.pdf'), 'r') do |file2|
          File.open(file_fixture('text-sample.txt'), 'r') do |file3|
            # Reversed file ingested order to test that ordered files are
            # returned in alphabetical order
            @item.add_and_ingest_files([file3, file2, file1])
          end
        end
      end
    end

    @item2 = Item.new(visibility: JupiterCore::VISIBILITY_AUTHENTICATED,
                      owner_id: @user.id, title: 'CCID Item',
                      creators: ['Joe Blow'],
                      created: '2011-11-11',
                      languages: [ControlledVocabulary.era.language.english],
                      license: ControlledVocabulary.era.license.attribution_4_0_international,
                      item_type: ControlledVocabulary.era.item_type.article,
                      publication_status: [ControlledVocabulary.era.publication_status.published],
                      subject: ['Fancy things'])
                 .tap do |uo|
      uo.add_to_path(@community.id, @collection.id)
      uo.add_to_path(@community.id, @collection.id)
      uo.save!
    end

    @thesis = Thesis.new(
      title: 'Thesis about the effects of missing regression tests',
      graduation_date: 'Fall 1990',
      dissertant: 'Joe Blow',
      abstract: generate_random_string,
      language: ControlledVocabulary.era.language.english,
      specialization: 'Failure Analysis',
      departments: ["Deparment of Makin' Computers Compute"],
      supervisors: ['Alan Turing (Department of Mathematics)'],
      committee_members: ['Alonzo Church (Department of Mathematics)'],
      rights: 'Share my stuff with everybody',
      thesis_level: 'Doctorate',
      degree: "Doctorate of Failin' Hard or Hardly Failin'",
      institution: ControlledVocabulary.era.institution.uofa,
      visibility: JupiterCore::VISIBILITY_PUBLIC,
      owner_id: @user.id
    ).tap do |uo|
      uo.add_to_path(@community.id, @collection.id)
      uo.add_to_path(@community.id, @collection.id)
      uo.save!
    end
  end

  test 'unauthed users should be able to download all files from a public item' do
    visit item_path @item

    assert_selector '.js-download', count: 3
    assert_selector '.js-download-all'
    # TODO: test that the files are downloaded via js successfully without making the suite brittle
  end

  test 'Search faceting on item values is not broken' do
    visit item_path @item
    click_link 'Joe Blow'

    assert_selector "a[href='/search?tab=item']", count: 1
  end

  test 'Check item files are listed alphabetically' do
    visit item_path @item

    assert_selector :xpath, "(.//div[contains(@class, 'item-filename')])", count: 3
    # Item files have been sorted by its ordered_files method
    assert_selector :xpath, "(.//div[contains(@class, 'item-filename')])[1]", text: 'image-sample.jpeg'
    assert_selector :xpath, "(.//div[contains(@class, 'item-filename')])[2]", text: 'pdf-sample.pdf'
    assert_selector :xpath, "(.//div[contains(@class, 'item-filename')])[3]", text: 'text-sample.txt'
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
