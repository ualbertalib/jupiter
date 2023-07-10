require 'test_helper'

class DataciteDoiServiceTest < ActiveSupport::TestCase

  include ActiveJob::TestHelper

  # If you need to re-record the vcr cassettes use SEED=20 to record the tests in order

  setup do
    Rails.application.secrets.doi_minting_enabled = true

    @admin = users(:user_admin)
    @item = items(:item_admin)
  end

  teardown do
    Rails.application.secrets.doi_minting_enabled = false
  end

  test 'mint DOI' do
    VCR.use_cassette('datacite_minting', erb: { id: @item.id }, record: :once) do
      assert_no_enqueued_jobs
      @item.update(doi: nil)

      assert_enqueued_jobs 1, only: DOICreateJob
      clear_enqueued_jobs

      assert_equal 'unminted', @item.aasm_state

      datacite_identifer = DOIService.new(@item).create

      assert_not_nil datacite_identifer
      assert_equal @item.doi.delete_prefix('doi:'), datacite_identifer.doi
      assert_equal 'University of Alberta Library', datacite_identifer.publisher
      assert_equal @item.title, datacite_identifer.titles.first[:title]
      assert_equal @item.description, datacite_identifer.descriptions.first[:description]
      assert_equal 'Image', datacite_identifer.types[:resourceType]
      assert_equal 2000, datacite_identifer.publicationYear
      assert_equal Datacite::State::FINDABLE, datacite_identifer.state

      assert_not_nil @item.doi
      assert_equal 'available', @item.aasm_state
    end
  end

  test 'mint DOI for Thesis' do
    thesis = thesis(:thesis_admin).decorate
    VCR.use_cassette('datacite_minting_for_thesis', erb: { id: thesis.id }, record: :once) do
      assert_no_enqueued_jobs
      thesis.update(doi: nil, aasm_state: :not_available)

      assert_enqueued_jobs 1, only: DOICreateJob
      clear_enqueued_jobs

      assert_equal 'unminted', thesis.aasm_state

      datacite_identifer = DOIService.new(thesis).create

      assert_not_nil datacite_identifer
      assert_equal thesis.doi.delete_prefix('doi:'), datacite_identifer.doi
      assert_equal 'University of Alberta Library', datacite_identifer.publisher
      assert_equal thesis.title, datacite_identifer.titles.first[:title]
      assert_equal thesis.description, datacite_identifer.descriptions.first[:description]
      assert_equal 'Text/Thesis', datacite_identifer.types[:resourceType]
      assert_equal 2015, datacite_identifer.publicationYear
      assert_equal Datacite::State::FINDABLE, datacite_identifer.state

      assert_not_nil thesis.doi
      assert_equal 'available', thesis.aasm_state
    end
  end

  test 'update DOI' do
    VCR.use_cassette('datacite_updating', erb: { id: @item.id }, record: :once) do
      assert_no_enqueued_jobs
      @item.update(title: 'Different Title', aasm_state: :available)

      assert_enqueued_jobs 1, only: DOIUpdateJob
      clear_enqueued_jobs

      datacite_identifer = DOIService.new(@item).update

      assert_not_nil datacite_identifer
      assert_equal @item.doi.delete_prefix('doi:'), datacite_identifer.doi
      assert_equal Datacite::State::FINDABLE, datacite_identifer.state
      assert_equal 'Different Title', datacite_identifer.titles.first[:title]
      assert_equal 'available', @item.aasm_state
    end
  end

  test 'unavailable DOI' do
    VCR.use_cassette('datacite_updating_unavailable', erb: { id: @item.id }, record: :once) do
      assert_no_enqueued_jobs

      @item.update(aasm_state: :available, visibility: JupiterCore::VISIBILITY_PRIVATE)

      assert_enqueued_jobs 1, only: DOIUpdateJob
      clear_enqueued_jobs

      datacite_identifer = DOIService.new(@item).update

      assert_not_nil datacite_identifer
      assert_equal @item.doi.delete_prefix('doi:'), datacite_identifer.doi
      assert_equal Datacite::State::REGISTERED, datacite_identifer.state
      assert_equal 'unavailable| not publicly released', datacite_identifer.reason
      assert_equal 'not_available', @item.aasm_state
    end
  end

  test 'remove DOI' do
    VCR.use_cassette('datacite_removal', erb: { id: @item.id }, record: :once, allow_unused_http_interactions: false) do
      assert_no_enqueued_jobs

      @item.destroy

      assert_enqueued_jobs 1, only: DOIRemoveJob
      clear_enqueued_jobs

      datacite_identifer = DOIService.remove(@item.doi)

      assert_not_nil datacite_identifer
      assert_equal @item.doi.delete_prefix('doi:'), datacite_identifer.doi
      assert_equal Datacite::State::REGISTERED, datacite_identifer.state
      assert_equal 'unavailable | withdrawn', datacite_identifer.reason
    end
  end

end
