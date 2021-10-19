require 'test_helper'

class DataciteDoiServiceTest < ActiveSupport::TestCase

  include ActiveJob::TestHelper

  EXAMPLE_DOI = '10.80243/wvg2-0805'.freeze

  setup do
    Datacite.configure do |config|
      config.password = ENV['DATACITE_PASSWORD']
    end
  end

  # rubocop:disable Minitest/MultipleAssertions
  # TODO: our tests are quite smelly.  This one needs work!
  test 'DOI state transitions' do
    Flipper.enable(:datacite_api)

    @admin = users(:user_admin)

    assert_no_enqueued_jobs only: DOIRemoveJob
    Rails.application.secrets.doi_minting_enabled = true

    community = Community.new(title: 'Community', owner_id: @admin.id,
                              visibility: JupiterCore::VISIBILITY_PUBLIC)

    community.save!
    collection = Collection.new(title: 'Collection', owner_id: @admin.id,
                                visibility: JupiterCore::VISIBILITY_PUBLIC,
                                community_id: community.id)
    collection.save!

    item = Item.new(title: 'Test Title', owner_id: @admin.id, visibility: JupiterCore::VISIBILITY_PUBLIC,
                    created: '2017-02-02',
                    languages: [ControlledVocabulary.era.language.english],
                    creators: ['Joe Blow'],
                    subject: ['Things'],
                    license: ControlledVocabulary.era.license.attribution_4_0_international,
                    item_type: ControlledVocabulary.era.item_type.book)
    item.tap do |unlocked_item|
      unlocked_item.add_to_path(community.id, collection.id)
      unlocked_item.save!
    end

    assert_nil item.doi
    assert_enqueued_jobs 1, only: DOICreateJob

    clear_enqueued_jobs

    VCR.use_cassette('datacite_minting', erb: { id: item.id }, record: :once) do
      assert_equal 'unminted', item.aasm_state

      datacite_identifer = DOIService.new(item).create
      assert_not_nil datacite_identifer
      assert_equal EXAMPLE_DOI, datacite_identifer.doi
      assert_equal 'University of Alberta Library', datacite_identifer.publisher
      assert_equal 'Test Title', datacite_identifer.titles.first[:title]
      assert_equal 'Text/Book', datacite_identifer.types[:resourceType]
      assert_equal 2017, datacite_identifer.publicationYear
      assert_equal Datacite::State::FINDABLE, datacite_identifer.state

      assert_not_nil item.doi
      assert_equal 'available', item.aasm_state
    end

    VCR.use_cassette('datacite_updating', erb: { id: item.id }, record: :once) do
      assert_no_enqueued_jobs only: DOIRemoveJob
      item.tap do |uo|
        uo.title = 'Different Title'
        uo.save!
      end

      assert_enqueued_jobs 1, only: DOIUpdateJob
      clear_enqueued_jobs

      datacite_identifer = DOIService.new(item).update
      assert_not_nil datacite_identifer
      assert_equal EXAMPLE_DOI, datacite_identifer.doi
      assert_equal Datacite::State::FINDABLE, datacite_identifer.state
      assert_equal 'Different Title', datacite_identifer.titles.first[:title]
      assert_equal 'available', item.aasm_state
    end

    VCR.use_cassette('datacite_updating_unavailable', erb: { id: item.id }, record: :once) do
      assert_no_enqueued_jobs only: DOIRemoveJob

      item.tap do |uo|
        uo.visibility = JupiterCore::VISIBILITY_PRIVATE
        uo.save!
      end

      assert_enqueued_jobs 1, only: DOIUpdateJob
      clear_enqueued_jobs

      datacite_identifer = DOIService.new(item).update
      assert_not_nil datacite_identifer
      assert_equal EXAMPLE_DOI, datacite_identifer.doi
      assert_equal Datacite::State::REGISTERED, datacite_identifer.state
      assert_equal 'unavailable | not publicly released', datacite_identifer.reason
      assert_equal 'not_available', item.aasm_state
    end

    VCR.use_cassette('datacite_removal', erb: { id: item.id }, record: :once, allow_unused_http_interactions: false) do
      assert_no_enqueued_jobs only: DOIRemoveJob

      item.tap(&:destroy)

      assert_enqueued_jobs 1, only: DOIRemoveJob
      clear_enqueued_jobs

      datacite_identifer = DOIService.remove(item.doi)
      assert_not_nil datacite_identifer
      assert_equal EXAMPLE_DOI, datacite_identifer.doi
      assert_equal Datacite::State::REGISTERED, datacite_identifer.state
      assert_equal 'unavailable | withdrawn', datacite_identifer.reason
    end

    Rails.application.secrets.doi_minting_enabled = false
    Flipper.disable(:datacite_api)
  end
  # rubocop:enable Minitest/MultipleAssertions

end
