require 'test_helper'

class DoiServiceTest < ActiveSupport::TestCase

  include ActiveJob::TestHelper

  EXAMPLE_DOI = 'doi:10.5072/FK2JQ1005X'.freeze

  test 'DOI state transitions' do
    assert_no_enqueued_jobs

    Rails.application.secrets.doi_minting_enabled = true

    community = Community.new_locked_ldp_object(title: 'Community', owner: 1,
                                                visibility: JupiterCore::VISIBILITY_PUBLIC)

    community.unlock_and_fetch_ldp_object(&:save!)
    collection = Collection.new_locked_ldp_object(title: 'Collection', owner: 1,
                                                  visibility: JupiterCore::VISIBILITY_PUBLIC,
                                                  community_id: community.id)
    collection.unlock_and_fetch_ldp_object(&:save!)

    item = Item.new_locked_ldp_object(title: 'Test Title', owner: 1, visibility: JupiterCore::VISIBILITY_PUBLIC,
                                      created: '2017-02-02',
                                      languages: [CONTROLLED_VOCABULARIES[:language].english],
                                      creators: ['Joe Blow'],
                                      subject: ['Things'],
                                      license: CONTROLLED_VOCABULARIES[:license].attribution_4_0_international,
                                      item_type: CONTROLLED_VOCABULARIES[:item_type].book)
    item.unlock_and_fetch_ldp_object do |unlocked_item|
      unlocked_item.add_to_path(community.id, collection.id)
      unlocked_item.save!
    end

    assert_nil item.doi
    assert_enqueued_jobs 1, only: DOICreateJob

    clear_enqueued_jobs

    VCR.use_cassette('ezid_minting', erb: { id: item.id }, record: :none) do
      assert_equal 'unminted', item.doi_state.aasm_state

      ezid_identifer = DOIService.new(item).create
      refute_nil ezid_identifer
      assert_equal EXAMPLE_DOI, ezid_identifer.id
      assert_equal 'University of Alberta Libraries', ezid_identifer.datacite_publisher
      assert_equal 'Test Title', ezid_identifer.datacite_title
      assert_equal 'Text/Book', ezid_identifer.datacite_resourcetype
      assert_equal '(:unav)', ezid_identifer.datacite_publicationyear
      assert_equal Ezid::Status::PUBLIC, ezid_identifer.status
      assert_equal 'yes', ezid_identifer.export

      refute_nil item.doi
      assert_equal 'available', item.doi_state.aasm_state
    end

    VCR.use_cassette('ezid_updating', erb: { id: item.id }, record: :none) do
      assert_no_enqueued_jobs

      item.unlock_and_fetch_ldp_object do |uo|
        uo.title = 'Different Title'
        uo.save!
      end
      assert_enqueued_jobs 1, only: DOIUpdateJob
      clear_enqueued_jobs

      ezid_identifer = DOIService.new(item).update
      refute_nil ezid_identifer
      assert_equal EXAMPLE_DOI, ezid_identifer.id
      assert_equal Ezid::Status::PUBLIC, ezid_identifer.status
      assert_equal 'Different Title', ezid_identifer.datacite_title
      assert_equal 'yes', ezid_identifer.export
      assert_equal 'available', item.doi_state.aasm_state
    end

    VCR.use_cassette('ezid_updating_unavailable', erb: { id: item.id }, record: :none) do
      assert_no_enqueued_jobs

      item.unlock_and_fetch_ldp_object do |uo|
        uo.visibility = JupiterCore::VISIBILITY_PRIVATE
        uo.save!
      end

      assert_enqueued_jobs 1, only: DOIUpdateJob
      clear_enqueued_jobs

      ezid_identifer = DOIService.new(item).update
      refute_nil ezid_identifer
      assert_equal EXAMPLE_DOI, ezid_identifer.id
      assert_equal 'unavailable | not publicly released', ezid_identifer.status
      assert_equal 'no', ezid_identifer.export
      assert_equal 'not_available', item.doi_state.aasm_state
    end

    VCR.use_cassette('ezid_removal', erb: { id: item.id }, record: :none, allow_unused_http_interactions: false) do
      assert_equal 0, Sidekiq::Worker.jobs.size
      item.unlock_and_fetch_ldp_object(&:destroy)

      assert_enqueued_jobs 1, only: DOIRemoveJob
      clear_enqueued_jobs

      ezid_identifer = DOIService.remove(item.doi)
      refute_nil ezid_identifer
      assert_equal EXAMPLE_DOI, ezid_identifer.id
      assert_equal 'unavailable | withdrawn', ezid_identifer.status
      assert_equal 'no', ezid_identifer.export
    end
  end

end
