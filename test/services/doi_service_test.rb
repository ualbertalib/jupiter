require 'test_helper'

class DoiServiceTest < ActiveSupport::TestCase

  EXAMPLE_DOI = 'doi:10.5072/FK2JQ1003W'.freeze

  test 'creation' do

    VCR.use_cassette('ezid_minting') do
      ezid_identifer = DOIService.new(item).create
      assert_nil ezid_identifer
    end

    assert_nil item.doi

    VCR.use_cassette('ezid_minting') do
      assert_equal 'unminted', item.doi_state.aasm_state
      item.unlock_and_fetch_ldp_object do |uo|
        uo.visibility = JupiterCore::VISIBILITY_PUBLIC
        uo.save
      end

      ezid_identifer = DOIService.new(item).create
      refute_nil ezid_identifer
      assert_equal 'University of Alberta Libraries', ezid_identifer.datacite_publisher
      assert_equal 'Test Title', ezid_identifer.datacite_title
      assert_equal 'Text/Book', ezid_identifer.datacite_resourcetype
      assert_equal '(:unav)', ezid_identifer.datacite_publicationyear
      assert_equal Ezid::Status::PUBLIC, ezid_identifer.status
      assert_equal 'yes', ezid_identifer.export

      refute_nil item.doi
      binding.pry
      assert_equal 'available', item.doi_state.aasm_state
    end
  end
end
