require 'test_helper'

class OaisysListSetsTest < ActionDispatch::IntegrationTest

  include Oaisys::Engine.routes.url_helpers

  setup do
    @routes = Oaisys::Engine.routes
    Oaisys::Engine.config.items_per_request = 3
  end

  test 'test_list_sets_resumption_token_xml' do
    get oaisys_path(verb: 'ListSets'), headers: { 'Accept' => 'application/xml' }
    assert_response :success

    schema = Nokogiri::XML::Schema(File.open(file_fixture('OAI-PMH.xsd')))
    document = Nokogiri::XML(@response.body)
    assert_empty schema.validate(document)

    top_level_sets = Oaisys::Engine.config.top_level_sets_model.pluck(:id, :title)
    sets = Oaisys::Engine.config.set_model.page(1)
                         .per(Oaisys::Engine.config.items_per_request)
                         .pluck(:community_id, :id, :title, :description)
    assert_select 'OAI-PMH' do
      assert_select 'responseDate'
      assert_select 'request'
      assert_select 'ListSets' do
        sets.each do |community_id, id, title, description|
          assert_select 'set' do
            assert_select 'setSpec', "#{community_id}:#{id}"
            assert_select 'setName', "#{top_level_sets.find { |a| a[0] == community_id }[1]} / #{title}"
            if description.present?
              assert_select 'setDescription' do
                assert_select 'oai_dc|dc' do
                  assert_select 'dc|description', description
                end
              end
            end
          end
        end
        assert_select 'resumptionToken'
      end
    end

    resumption_token = document.css('OAI-PMH ListSets resumptionToken').text
    # TODO: look into why every second request to Oaisys in the same test gives a 503.
    get oaisys_path(verb: 'ListSets', resumptionToken: resumption_token),
        headers: { 'Accept' => 'application/xml' }

    # Test use of resumption token.
    get oaisys_path(verb: 'ListSets', resumptionToken: resumption_token),
        headers: { 'Accept' => 'application/xml' }
    assert_response :success

    schema = Nokogiri::XML::Schema(File.open(file_fixture('OAI-PMH.xsd')))
    document = Nokogiri::XML(@response.body)
    assert_empty schema.validate(document)

    top_level_sets = Oaisys::Engine.config.top_level_sets_model.pluck(:id, :title)
    sets = Oaisys::Engine.config.set_model.page(2)
                         .per(Oaisys::Engine.config.items_per_request)
                         .pluck(:community_id, :id, :title, :description)
    assert_select 'OAI-PMH' do
      assert_select 'responseDate'
      assert_select 'request'
      assert_select 'ListSets' do
        sets.each do |community_id, id, title, description|
          assert_select 'set' do
            assert_select 'setSpec', "#{community_id}:#{id}"
            assert_select 'setName', "#{top_level_sets.find { |a| a[0] == community_id }[1]} / #{title}"
            if description.present?
              assert_select 'setDescription' do
                assert_select 'oai_dc|dc' do
                  assert_select 'dc|description', description
                end
              end
            end
          end
        end
        assert_select 'resumptionToken'
      end
    end

    resumption_token = document.css('OAI-PMH ListIdentifiers resumptionToken').text
    # TODO: look into why every second request to Oaisys in the same test gives a 503.
    get oaisys_path(verb: 'ListIdentifiers', resumptionToken: resumption_token),
        headers: { 'Accept' => 'application/xml' }

    # Test expiration of resumption token when results change.
    Collection.create!(community_id: communities(:books).id,
                       title: 'Fancy Collection 7', owner_id: users(:admin).id,
                       description: '')

    get oaisys_path(verb: 'ListSets', resumptionToken: resumption_token),
        headers: { 'Accept' => 'application/xml' }
    assert_response :success

    assert_select 'OAI-PMH' do
      assert_select 'responseDate'
      assert_select 'request'
      assert_select 'error', I18n.t('error_messages.resumption_token_invalid')
    end
  end

end
