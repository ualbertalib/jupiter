require 'test_helper'

class DoiServiceTest < ActiveSupport::TestCase

  include ActiveJob::TestHelper

  EXAMPLE_DOI = 'doi:10.21967/fk2-ycs2-dd92'.freeze

  test 'DOI state transitions' do
    @admin = users(:admin)

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
                    languages: [CONTROLLED_VOCABULARIES[:language].english],
                    creators: ['Joe Blow'],
                    subject: ['Things'],
                    license: CONTROLLED_VOCABULARIES[:license].attribution_4_0_international,
                    item_type: CONTROLLED_VOCABULARIES[:item_type].book)
    item.tap do |unlocked_item|
      unlocked_item.add_to_path(community.id, collection.id)
      unlocked_item.save!
    end

    assert_nil item.doi
    assert_enqueued_jobs 1, only: DOICreateJob

    clear_enqueued_jobs

    VCR.use_cassette('ezid_minting', erb: { id: item.id }, record: :none) do
      assert_equal 'unminted', item.aasm_state

      ezid_identifer = DOIService.new(item).create
      assert_not_nil ezid_identifer
      assert_equal EXAMPLE_DOI, ezid_identifer.id
      assert_equal 'University of Alberta Libraries', ezid_identifer.datacite_publisher
      assert_equal 'Test Title', ezid_identifer.datacite_title
      assert_equal 'Text/Book', ezid_identifer.datacite_resourcetype
      assert_equal '2017', ezid_identifer.datacite_publicationyear
      assert_equal Ezid::Status::PUBLIC, ezid_identifer.status
      assert_equal 'yes', ezid_identifer.export

      assert_not_nil item.doi
      assert_equal 'available', item.aasm_state
    end

    VCR.use_cassette('ezid_updating', erb: { id: item.id }, record: :none) do
      assert_no_enqueued_jobs only: DOIRemoveJob
      item.tap do |uo|
        uo.title = 'Different Title'
        uo.save!
      end

      assert_enqueued_jobs 1, only: DOIUpdateJob
      clear_enqueued_jobs

      ezid_identifer = DOIService.new(item).update
      assert_not_nil ezid_identifer
      assert_equal EXAMPLE_DOI, ezid_identifer.id
      assert_equal Ezid::Status::PUBLIC, ezid_identifer.status
      assert_equal 'Different Title', ezid_identifer.datacite_title
      assert_equal 'yes', ezid_identifer.export
      assert_equal 'available', item.aasm_state
    end

    VCR.use_cassette('ezid_updating_unavailable', erb: { id: item.id }, record: :none) do
      assert_no_enqueued_jobs only: DOIRemoveJob

      item.tap do |uo|
        uo.visibility = JupiterCore::VISIBILITY_PRIVATE
        uo.save!
      end

      assert_enqueued_jobs 1, only: DOIUpdateJob
      clear_enqueued_jobs

      ezid_identifer = DOIService.new(item).update
      assert_not_nil ezid_identifer
      assert_equal EXAMPLE_DOI, ezid_identifer.id
      assert_equal 'unavailable | not publicly released', ezid_identifer.status
      assert_equal 'not_available', item.aasm_state
    end

    VCR.use_cassette('ezid_removal', erb: { id: item.id }, record: :none, allow_unused_http_interactions: false) do
      assert_no_enqueued_jobs only: DOIRemoveJob

      item.tap(&:destroy)

      assert_enqueued_jobs 1, only: DOIRemoveJob
      clear_enqueued_jobs

      ezid_identifer = DOIService.remove(item.doi)
      assert_not_nil ezid_identifer
      assert_equal EXAMPLE_DOI, ezid_identifer.id
      assert_equal 'unavailable | withdrawn', ezid_identifer.status
      assert_equal 'no', ezid_identifer.export
    end

    Rails.application.secrets.doi_minting_enabled = false
  end

end
