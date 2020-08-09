require 'test_helper'

class OaisysListIdentifiersTest < ActionDispatch::IntegrationTest

  include Oaisys::Engine.routes.url_helpers

  setup do
    @routes = Oaisys::Engine.routes
    Oaisys::Engine.config.items_per_request = 2

    @community = communities(:fancy_community)
    @collection = collections(:fancy_collection)

    @thesis_collection = collections(:thesis)
    @embargoed_thesis_collection = collections(:embargoed_thesis)
  end

  test 'list identifers items xml' do
    get oaisys_path(verb: 'ListIdentifiers', metadataPrefix: 'oai_dc'), headers: { 'Accept' => 'application/xml' }
    assert_response :success

    schema = Nokogiri::XML::Schema(File.open(file_fixture('OAI-PMH.xsd')))
    document = Nokogiri::XML(@response.body)
    assert_empty schema.validate(document)

    item_identifiers = Oaisys::Engine.config.oai_dc_model.public_items.page(1)
                                     .per(Oaisys::Engine.config.items_per_request)
                                     .pluck(:id, :updated_at, :member_of_paths)
    assert_select 'OAI-PMH' do
      assert_select 'responseDate'
      assert_select 'request'
      assert_select 'ListIdentifiers' do
        item_identifiers.each do |identifier, date, sets|
          assert_select 'header' do
            assert_select 'identifier', "oai:era.library.ualberta.ca:#{identifier}"
            assert_select 'datestamp', date.utc.xmlschema
            sets.each do |set|
              assert_select 'setSpec', set.tr('/', ':')
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

    # Test use of resumption token.
    get oaisys_path(verb: 'ListIdentifiers', resumptionToken: resumption_token),
        headers: { 'Accept' => 'application/xml' }
    assert_response :success

    document = Nokogiri::XML(@response.body)
    assert_empty schema.validate(document)
    item_identifiers = Oaisys::Engine.config.oai_dc_model.public_items.page(2)
                                     .per(Oaisys::Engine.config.items_per_request)
                                     .pluck(:id, :updated_at, :member_of_paths)

    assert_select 'OAI-PMH' do
      assert_select 'responseDate'
      assert_select 'request'
      assert_select 'ListIdentifiers' do
        item_identifiers.each do |identifier, date, sets|
          assert_select 'header' do
            assert_select 'identifier', "oai:era.library.ualberta.ca:#{identifier}"
            assert_select 'datestamp', date.utc.xmlschema
            sets.each do |set|
              assert_select 'setSpec', set.tr('/', ':')
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
    @item = Item.new(visibility: JupiterCore::VISIBILITY_PUBLIC,
                     owner_id: users(:admin).id, title: 'Fancy Item 1',
                     creators: ['Joe Blow'],
                     created: '1938-01-02',
                     languages: [CONTROLLED_VOCABULARIES[:language].english],
                     item_type: CONTROLLED_VOCABULARIES[:item_type].article,
                     publication_status:
                       [CONTROLLED_VOCABULARIES[:publication_status].published],
                     license: CONTROLLED_VOCABULARIES[:license].attribution_4_0_international,
                     subject: ['Items']).tap do |uo|
      uo.add_to_path(@community.id, @collection.id)
      uo.save!
    end

    get oaisys_path(verb: 'ListIdentifiers', resumptionToken: resumption_token),
        headers: { 'Accept' => 'application/xml' }
    assert_response :success

    assert_select 'OAI-PMH' do
      assert_select 'responseDate'
      assert_select 'request'
      assert_select 'error', I18n.t('error_messages.resumption_token_invalid')
    end
  end

  test 'list identifers theses xml' do
    get oaisys_path(verb: 'ListIdentifiers', metadataPrefix: 'oai_etdms'), headers: { 'Accept' => 'application/xml' }
    assert_response :success

    schema = Nokogiri::XML::Schema(File.open(file_fixture('OAI-PMH.xsd')))
    document = Nokogiri::XML(@response.body)
    assert_empty schema.validate(document)
    thesis_identifiers = Oaisys::Engine.config.oai_etdms_model.public_items
                                       .limit(Oaisys::Engine.config.items_per_request)
                                       .pluck(:id, :updated_at, :member_of_paths)
    assert_select 'OAI-PMH' do
      assert_select 'responseDate'
      assert_select 'request'
      assert_select 'ListIdentifiers' do
        thesis_identifiers.each do |identifier, date, sets|
          assert_select 'header' do
            assert_select 'identifier', "oai:era.library.ualberta.ca:#{identifier}"
            assert_select 'datestamp', date.utc.xmlschema
            sets.each do |set|
              assert_select 'setSpec', set.tr('/', ':')
            end
          end
        end
      end
    end
  end

  test 'list identifers item set xml' do
    get oaisys_path(verb: 'ListIdentifiers', metadataPrefix: 'oai_dc', set: @collection.id),
        headers: { 'Accept' => 'application/xml' }
    assert_response :success

    schema = Nokogiri::XML::Schema(File.open(file_fixture('OAI-PMH.xsd')))
    document = Nokogiri::XML(@response.body)
    assert_empty schema.validate(document)

    item_identifiers = Oaisys::Engine.config.oai_dc_model.public_items.belongs_to_path(@collection.id)
                                     .limit(Oaisys::Engine.config.items_per_request)
                                     .pluck(:id, :updated_at, :member_of_paths)
    assert_select 'OAI-PMH' do
      assert_select 'responseDate'
      assert_select 'request'
      assert_select 'ListIdentifiers' do
        item_identifiers.each do |identifier, date, sets|
          assert_select 'header' do
            assert_select 'identifier', "oai:era.library.ualberta.ca:#{identifier}"
            assert_select 'datestamp', date.utc.xmlschema
            sets.each do |set|
              assert_select 'setSpec', set.tr('/', ':')
            end
          end
        end
      end
    end
  end

  test 'list identifers thesis set xml' do
    get oaisys_path(verb: 'ListIdentifiers', metadataPrefix: 'oai_etdms', set: @thesis_collection.id),
        headers: { 'Accept' => 'application/xml' }
    assert_response :success

    schema = Nokogiri::XML::Schema(File.open(file_fixture('OAI-PMH.xsd')))
    document = Nokogiri::XML(@response.body)
    assert_empty schema.validate(document)

    thesis_identifiers = Oaisys::Engine.config.oai_etdms_model.public_items.belongs_to_path(@thesis_collection.id)
                                       .limit(Oaisys::Engine.config.items_per_request)
                                       .pluck(:id, :updated_at, :member_of_paths)
    assert_select 'OAI-PMH' do
      assert_select 'responseDate'
      assert_select 'request'
      assert_select 'ListIdentifiers' do
        thesis_identifiers.each do |identifier, date, sets|
          assert_select 'header' do
            assert_select 'identifier', "oai:era.library.ualberta.ca:#{identifier}"
            assert_select 'datestamp', date.utc.xmlschema
            sets.each do |set|
              assert_select 'setSpec', set.tr('/', ':')
            end
          end
        end
      end
    end
  end

  test 'list identifers embargo thesis xml' do
    get oaisys_path(verb: 'ListIdentifiers', metadataPrefix: 'oai_etdms', set: @embargoed_thesis_collection.id),
        headers: { 'Accept' => 'application/xml' }
    assert_response :success

    schema = Nokogiri::XML::Schema(File.open(file_fixture('OAI-PMH.xsd')))
    document = Nokogiri::XML(@response.body)
    assert_empty schema.validate(document)
    assert_select 'OAI-PMH' do
      assert_select 'responseDate'
      assert_select 'request'
      assert_select 'error', I18n.t('error_messages.no_record_found')
    end
  end

  test 'list identifers item until date xml' do
    just_after_current_time = (Time.current + 5).utc.xmlschema
    get oaisys_path(verb: 'ListIdentifiers', metadataPrefix: 'oai_dc', set: @community.id,
                    until: just_after_current_time), headers: { 'Accept' => 'application/xml' }
    assert_response :success

    schema = Nokogiri::XML::Schema(File.open(file_fixture('OAI-PMH.xsd')))
    document = Nokogiri::XML(@response.body)
    assert_empty schema.validate(document)
    item_identifiers = Oaisys::Engine.config.oai_dc_model.public_items.updated_on_or_before(just_after_current_time)
                                     .limit(Oaisys::Engine.config.items_per_request)
                                     .belongs_to_path(@community.id).pluck(:id, :updated_at, :member_of_paths)
    assert_select 'OAI-PMH' do
      assert_select 'responseDate'
      assert_select 'request'
      assert_select 'ListIdentifiers' do
        item_identifiers.each do |identifier, date, sets|
          assert_select 'header' do
            assert_select 'identifier', "oai:era.library.ualberta.ca:#{identifier}"
            assert_select 'datestamp', date.utc.xmlschema
            sets.each do |set|
              assert_select 'setSpec', set.tr('/', ':')
            end
          end
        end
      end
    end
  end

  test 'list identifers thesis until date xml' do
    just_after_current_time = (Time.current + 5).utc.xmlschema
    get oaisys_path(verb: 'ListIdentifiers', metadataPrefix: 'oai_etdms', set: @thesis_collection.id,
                    until: just_after_current_time), headers: { 'Accept' => 'application/xml' }
    assert_response :success

    schema = Nokogiri::XML::Schema(File.open(file_fixture('OAI-PMH.xsd')))
    document = Nokogiri::XML(@response.body)
    assert_empty schema.validate(document)
    thesis_identifiers = Oaisys::Engine.config.oai_etdms_model
                                       .public_items.updated_on_or_before(just_after_current_time)
                                       .belongs_to_path(@thesis_collection.id)
                                       .limit(Oaisys::Engine.config.items_per_request)
                                       .pluck(:id, :updated_at, :member_of_paths)
    assert_select 'OAI-PMH' do
      assert_select 'responseDate'
      assert_select 'request'
      assert_select 'ListIdentifiers' do
        thesis_identifiers.each do |identifier, date, sets|
          assert_select 'header' do
            assert_select 'identifier', "oai:era.library.ualberta.ca:#{identifier}"
            assert_select 'datestamp', date.utc.xmlschema
            sets.each do |set|
              assert_select 'setSpec', set.tr('/', ':')
            end
          end
        end
      end
    end
  end

  test 'list identifers item from date xml' do
    six_days_from_now = (Time.current + 6.days).utc.xmlschema
    get oaisys_path(verb: 'ListIdentifiers', metadataPrefix: 'oai_dc', set: @community.id,
                    from: six_days_from_now), headers: { 'Accept' => 'application/xml' }
    assert_response :success

    schema = Nokogiri::XML::Schema(File.open(file_fixture('OAI-PMH.xsd')))
    document = Nokogiri::XML(@response.body)
    assert_empty schema.validate(document)

    assert_select 'OAI-PMH' do
      assert_select 'responseDate'
      assert_select 'request'
      assert_select 'error', I18n.t('error_messages.no_record_found')
    end
  end

  test 'list identifers thesis from date xml' do
    six_days_from_now = (Time.current + 5).utc.xmlschema
    get oaisys_path(verb: 'ListIdentifiers', metadataPrefix: 'oai_etdms', set: @thesis_collection.id,
                    from: six_days_from_now), headers: { 'Accept' => 'application/xml' }
    assert_response :success

    schema = Nokogiri::XML::Schema(File.open(file_fixture('OAI-PMH.xsd')))
    document = Nokogiri::XML(@response.body)
    assert_empty schema.validate(document)

    assert_select 'OAI-PMH' do
      assert_select 'responseDate'
      assert_select 'request'
      assert_select 'error', I18n.t('error_messages.no_record_found')
    end
  end

  test 'list identifers item from until date xml' do
    item = Oaisys::Engine.config.oai_dc_model.public_items.belongs_to_path(@community.id).first
    item_creation_time = item[:updated_at].utc.xmlschema
    just_after_item_creation_time = (item[:updated_at] + 5.seconds).utc.xmlschema
    get oaisys_path(verb: 'ListIdentifiers', metadataPrefix: 'oai_dc', set: @community.id, from: item_creation_time,
                    until: just_after_item_creation_time),
        headers: { 'Accept' => 'application/xml' }
    assert_response :success

    schema = Nokogiri::XML::Schema(File.open(file_fixture('OAI-PMH.xsd')))
    document = Nokogiri::XML(@response.body)
    assert_empty schema.validate(document)

    assert_select 'OAI-PMH' do
      assert_select 'responseDate'
      assert_select 'request'
      assert_select 'ListIdentifiers' do
        assert_select 'header' do
          assert_select 'identifier', "oai:era.library.ualberta.ca:#{item[:id]}"
          assert_select 'datestamp', item_creation_time
          item[:member_of_paths].each do |set|
            assert_select 'setSpec', set.tr('/', ':')
          end
        end
      end
    end
  end

  test 'list identifers thesis from until date xml' do
    thesis = Oaisys::Engine.config.oai_etdms_model.public_items.belongs_to_path(@thesis_collection.id).first
    thesis_creation_time = thesis[:updated_at].utc.xmlschema
    just_after_thesis_creation_time = (thesis[:updated_at] + 5.seconds).utc.xmlschema
    get oaisys_path(verb: 'ListIdentifiers', metadataPrefix: 'oai_etdms', set: @thesis_collection.id,
                    from: thesis_creation_time, until: just_after_thesis_creation_time),
        headers: { 'Accept' => 'application/xml' }
    assert_response :success

    schema = Nokogiri::XML::Schema(File.open(file_fixture('OAI-PMH.xsd')))
    document = Nokogiri::XML(@response.body)
    assert_empty schema.validate(document)

    assert_select 'OAI-PMH' do
      assert_select 'responseDate'
      assert_select 'request'
      assert_select 'ListIdentifiers' do
        assert_select 'header' do
          assert_select 'identifier', "oai:era.library.ualberta.ca:#{thesis[:id]}"
          assert_select 'datestamp', thesis_creation_time
          thesis[:member_of_paths].each do |set|
            assert_select 'setSpec', set.tr('/', ':')
          end
        end
      end
    end
  end

end
