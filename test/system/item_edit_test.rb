require 'application_system_test_case'

class ItemEditTest < ApplicationSystemTestCase

  test 'can edit item' do
    skip "this test is flapping like crazy, I think there's a timing issue with selectize_clear_all?"
    user = User.find_by(email: 'john_snow@example.com')

    admin = User.find_by(email: 'administrator@example.com')
    community = communities(:books)
    collection = collections(:fantasy_books)

    item = Item.new(visibility: JupiterCore::VISIBILITY_PUBLIC,
                    title: 'Book of Random',
                    owner_id: user.id,
                    item_type: CONTROLLED_VOCABULARIES[:item_type].book,
                    languages: [CONTROLLED_VOCABULARIES[:language].english],
                    creators: ['Jane Doe', 'Bob Smith'],
                    subject: ['Best Seller', 'Adventure'],
                    created: '2018-10-24',
                    description: 'Really random description about this random book',
                    license: CONTROLLED_VOCABULARIES[:license].attribution_4_0_international,
                    contributors: ['Sue Flowers', 'Jonny Green'])
               .tap do |uo|
      uo.add_to_path(community.id, collection.id)
      uo.save!
    end
    Sidekiq::Testing.inline! do
      File.open(file_fixture('image-sample.jpeg'), 'r') do |file|
        item.add_and_ingest_files([file])
      end
    end

    login_user user

    visit item_path item

    click_on I18n.t('more_information')
    assert_selector 'dt', text: 'Additional contributors'

    click_on I18n.t('application.navbar.links.login') # TODO: not sure why the login didn't persist

    click_on I18n.t('edit')

    assert_selector 'h1', text: I18n.t('items.draft.header_edit')
    click_on I18n.t('items.draft.describe_item.additional_fields')

    selectize_clear_all '.draft_item_contributors'

    click_on I18n.t('items.draft.save_and_continue')

    click_on I18n.t('items.draft.save_and_continue')
    click_on I18n.t('items.draft.save_and_continue')
    refute_selector 'h6', text: 'Additional contributors'

    click_on I18n.t('items.draft.save_and_deposit_edits')
    assert_text I18n.t('items.draft.successful_deposit')

    click_on I18n.t('more_information')
    refute_selector 'dt', text: 'Additional contributors'

    logout_user
  end

  # Helper methods for javascript fields (selectize)
  # (could be moved and made as generic helpers if these are needed elsewhere)
  private

  # TODO: remove individual item based on value
  def selectize_clear_all(key)
    within key do
      first('.selectize-input input').click
      first('.selectize-input input').send_keys [:control, 'a'], :delete
    end
  end

end
