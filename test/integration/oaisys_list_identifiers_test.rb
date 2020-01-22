require 'test_helper'

class OaisysListIdentifiersTest < ActionDispatch::IntegrationTest

  include Oaisys::Engine.routes.url_helpers

  setup do
    @routes = Oaisys::Engine.routes
    Oaisys::Engine.config.items_per_request = 5
  end

  def before_all
    super
    Item.destroy_all
    Thesis.destroy_all
    @community = Community.create!(title: 'Fancy Community', owner_id: users(:admin).id)
    @big_community = Community.create!(title: 'Big Community', owner_id: users(:admin).id)
    @big_collection = Collection.create!(community_id: @big_community.id,
                                         title: 'Big Collection', owner_id: users(:admin).id)

    @collection1 = Collection.create!(community_id: @community.id,
                                      title: 'Fancy Collection 1', owner_id: users(:admin).id)
    @collection2 = Collection.create!(community_id: @community.id,
                                      title: 'Fancy Collection 2', owner_id: users(:admin).id)
    @embargo_collection = Collection.create!(community_id: @community.id,
                                             title: 'Embargo Collection', owner_id: users(:admin).id)
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
      uo.add_to_path(@community.id, @collection1.id)
      uo.save!
    end

    travel_to 2.seconds.from_now do
      @item = Item.new(visibility: JupiterCore::VISIBILITY_PUBLIC,
                       owner_id: users(:admin).id, title: 'Fancy Item 2',
                       creators: ['Jane Doe'],
                       created: '1938-01-02',
                       languages: [CONTROLLED_VOCABULARIES[:language].english],
                       item_type: CONTROLLED_VOCABULARIES[:item_type].article,
                       publication_status:
                         [CONTROLLED_VOCABULARIES[:publication_status].published],
                       license: CONTROLLED_VOCABULARIES[:license].attribution_4_0_international,
                       subject: ['Items']).tap do |uo|
        uo.add_to_path(@community.id, @collection2.id)
        uo.save!
      end

      @thesis_in_embargo = Thesis.new(
        title: 'thesis 1',
        owner_id: users(:admin).id,
        dissertant: 'Joe Blow',
        graduation_date: '2017-03-31',
        visibility: JupiterCore::Depositable::VISIBILITY_EMBARGO,
        embargo_end_date: 2.days.from_now.to_date,
        visibility_after_embargo: CONTROLLED_VOCABULARIES[:visibility].public
      ).tap do |unlocked_thesis|
        unlocked_thesis.add_to_path(@community.id, @embargo_collection.id)
        unlocked_thesis.save!
      end
    end

    travel_to 4.seconds.from_now do
      @thesis1 = Thesis.new(visibility: JupiterCore::VISIBILITY_PUBLIC,
                            owner_id: users(:admin).id, title: 'Fancy thesis 1',
                            dissertant: 'Joe Blow',
                            language: CONTROLLED_VOCABULARIES[:language].english,
                            graduation_date: 'Fall 2017')
                       .tap do |uo|
        uo.add_to_path(@community.id, @collection1.id)
        uo.save!
      end

      @thesis2 = Thesis.new(visibility: JupiterCore::VISIBILITY_PUBLIC,
                            owner_id: users(:admin).id, title: 'Fancy thesis 2',
                            dissertant: 'Jane Doe',
                            language: CONTROLLED_VOCABULARIES[:language].english,
                            graduation_date: 'Fall 2017')
                       .tap do |uo|
        uo.add_to_path(@community.id, @collection2.id)
        uo.save!
      end

      @items = 4.times.map do |i|
        Item.new(visibility: JupiterCore::VISIBILITY_PUBLIC,
                 owner_id: users(:admin).id, title: "#{['Fancy', 'Nice'][i % 2]} Item #{i}",
                 creators: ['Joe Blow'],
                 created: "#{1950 + i}-11-11",
                 languages: [CONTROLLED_VOCABULARIES[:language].english],
                 item_type: CONTROLLED_VOCABULARIES[:item_type].article,
                 publication_status: [CONTROLLED_VOCABULARIES[:publication_status].published],
                 license: CONTROLLED_VOCABULARIES[:license].attribution_4_0_international,
                 subject: ['Items'])
            .tap do |uo|
          uo.add_to_path(@big_community.id, @big_collection.id)
          uo.save!
        end
      end
    end
  end

  def test_list_identifiers_items_resumption_token_xml
    get oaisys_path(verb: 'ListIdentifiers', metadataPrefix: 'oai_dc'), headers: { 'Accept' => 'application/xml' }
    assert_response :success

    schema = Nokogiri::XML::Schema(File.open(file_fixture('OAI-PMH.xsd')))
    document = Nokogiri::XML(@response.body)
    assert_empty schema.validate(document)

    item_identifiers = Oaisys::Engine.config.oai_dc_model.public_items.page(1)
                                     .per(Oaisys::Engine.config.items_per_request)
                                     .pluck(:id, :record_created_at, :member_of_paths)
    assert_select 'OAI-PMH' do
      assert_select 'responseDate'
      assert_select 'request'
      assert_select 'ListIdentifiers' do
        item_identifiers.each do |identifier, date, sets|
          assert_select 'header' do
            assert_select 'identifier', 'oai:era.library.ualberta.ca:' + identifier
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
                                     .pluck(:id, :record_created_at, :member_of_paths)

    assert_select 'OAI-PMH' do
      assert_select 'responseDate'
      assert_select 'request'
      assert_select 'ListIdentifiers' do
        item_identifiers.each do |identifier, date, sets|
          assert_select 'header' do
            assert_select 'identifier', 'oai:era.library.ualberta.ca:' + identifier
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
      uo.add_to_path(@community.id, @collection1.id)
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

  def test_list_identifiers_theses_xml
    get oaisys_path(verb: 'ListIdentifiers', metadataPrefix: 'oai_etdms'), headers: { 'Accept' => 'application/xml' }
    assert_response :success

    schema = Nokogiri::XML::Schema(File.open(file_fixture('OAI-PMH.xsd')))
    document = Nokogiri::XML(@response.body)
    assert_empty schema.validate(document)
    thesis_identifiers = Oaisys::Engine.config.oai_etdms_model.public_items
                                       .pluck(:id, :record_created_at, :member_of_paths)
    assert_select 'OAI-PMH' do
      assert_select 'responseDate'
      assert_select 'request'
      assert_select 'ListIdentifiers' do
        thesis_identifiers.each do |identifier, date, sets|
          assert_select 'header' do
            assert_select 'identifier', 'oai:era.library.ualberta.ca:' + identifier
            assert_select 'datestamp', date.utc.xmlschema
            sets.each do |set|
              assert_select 'setSpec', set.tr('/', ':')
            end
          end
        end
      end
    end
  end

  def test_list_identifiers_item_set_xml
    get oaisys_path(verb: 'ListIdentifiers', metadataPrefix: 'oai_dc', set: @collection2.id),
        headers: { 'Accept' => 'application/xml' }
    assert_response :success

    schema = Nokogiri::XML::Schema(File.open(file_fixture('OAI-PMH.xsd')))
    document = Nokogiri::XML(@response.body)
    assert_empty schema.validate(document)

    item_identifiers = Oaisys::Engine.config.oai_dc_model.public_items.belongs_to_path(@collection2.id)
                                     .pluck(:id, :record_created_at, :member_of_paths)
    assert_select 'OAI-PMH' do
      assert_select 'responseDate'
      assert_select 'request'
      assert_select 'ListIdentifiers' do
        item_identifiers.each do |identifier, date, sets|
          assert_select 'header' do
            assert_select 'identifier', 'oai:era.library.ualberta.ca:' + identifier
            assert_select 'datestamp', date.utc.xmlschema
            sets.each do |set|
              assert_select 'setSpec', set.tr('/', ':')
            end
          end
        end
      end
    end
  end

  def test_list_identifiers_thesis_set_xml
    get oaisys_path(verb: 'ListIdentifiers', metadataPrefix: 'oai_etdms', set: @collection2.id),
        headers: { 'Accept' => 'application/xml' }
    assert_response :success

    schema = Nokogiri::XML::Schema(File.open(file_fixture('OAI-PMH.xsd')))
    document = Nokogiri::XML(@response.body)
    assert_empty schema.validate(document)

    thesis_identifiers = Oaisys::Engine.config.oai_etdms_model.public_items.belongs_to_path(@collection2.id)
                                       .pluck(:id, :record_created_at, :member_of_paths)
    assert_select 'OAI-PMH' do
      assert_select 'responseDate'
      assert_select 'request'
      assert_select 'ListIdentifiers' do
        thesis_identifiers.each do |identifier, date, sets|
          assert_select 'header' do
            assert_select 'identifier', 'oai:era.library.ualberta.ca:' + identifier
            assert_select 'datestamp', date.utc.xmlschema
            sets.each do |set|
              assert_select 'setSpec', set.tr('/', ':')
            end
          end
        end
      end
    end
  end

  def test_list_identifiers_embargo_thesis_xml
    get oaisys_path(verb: 'ListIdentifiers', metadataPrefix: 'oai_etdms', set: @embargo_collection.id),
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

  def test_list_identifiers_item_until_date_xml
    just_after_current_time = (Time.current + 5).utc.xmlschema
    get oaisys_path(verb: 'ListIdentifiers', metadataPrefix: 'oai_dc', set: @community.id,
                    until: just_after_current_time), headers: { 'Accept' => 'application/xml' }
    assert_response :success

    schema = Nokogiri::XML::Schema(File.open(file_fixture('OAI-PMH.xsd')))
    document = Nokogiri::XML(@response.body)
    assert_empty schema.validate(document)
    item_identifiers = Oaisys::Engine.config.oai_dc_model.public_items.created_on_or_before(just_after_current_time)
                                     .belongs_to_path(@community.id).pluck(:id, :record_created_at, :member_of_paths)
    assert_select 'OAI-PMH' do
      assert_select 'responseDate'
      assert_select 'request'
      assert_select 'ListIdentifiers' do
        item_identifiers.each do |identifier, date, sets|
          assert_select 'header' do
            assert_select 'identifier', 'oai:era.library.ualberta.ca:' + identifier
            assert_select 'datestamp', date.utc.xmlschema
            sets.each do |set|
              assert_select 'setSpec', set.tr('/', ':')
            end
          end
        end
      end
    end
  end

  def test_list_identifiers_thesis_until_date_xml
    just_after_current_time = (Time.current + 5).utc.xmlschema
    get oaisys_path(verb: 'ListIdentifiers', metadataPrefix: 'oai_etdms', set: @community.id,
                    until: just_after_current_time), headers: { 'Accept' => 'application/xml' }
    assert_response :success

    schema = Nokogiri::XML::Schema(File.open(file_fixture('OAI-PMH.xsd')))
    document = Nokogiri::XML(@response.body)
    assert_empty schema.validate(document)
    thesis_identifiers = Oaisys::Engine.config.oai_etdms_model
                                       .public_items.created_on_or_before(just_after_current_time)
                                       .belongs_to_path(@community.id)
                                       .pluck(:id, :record_created_at, :member_of_paths)
    assert_select 'OAI-PMH' do
      assert_select 'responseDate'
      assert_select 'request'
      assert_select 'ListIdentifiers' do
        thesis_identifiers.each do |identifier, date, sets|
          assert_select 'header' do
            assert_select 'identifier', 'oai:era.library.ualberta.ca:' + identifier
            assert_select 'datestamp', date.utc.xmlschema
            sets.each do |set|
              assert_select 'setSpec', set.tr('/', ':')
            end
          end
        end
      end
    end
  end

  def test_list_identifiers_item_from_date_xml
    just_after_current_time = (Time.current + 5).utc.xmlschema
    get oaisys_path(verb: 'ListIdentifiers', metadataPrefix: 'oai_dc', set: @community.id,
                    from: just_after_current_time), headers: { 'Accept' => 'application/xml' }
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

  def test_list_identifiers_thesis_from_date_xml
    just_after_current_time = (Time.current + 5).utc.xmlschema
    get oaisys_path(verb: 'ListIdentifiers', metadataPrefix: 'oai_etdms', set: @community.id,
                    from: just_after_current_time), headers: { 'Accept' => 'application/xml' }
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

  def test_list_identifiers_item_from_until_date_xml
    item = Oaisys::Engine.config.oai_dc_model.public_items.belongs_to_path(@community.id).first
    item_creation_time = item[:record_created_at].utc.xmlschema
    just_after_item_creation_time = (item[:record_created_at] + 5.seconds).utc.xmlschema
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
          assert_select 'identifier', 'oai:era.library.ualberta.ca:' + item[:id]
          assert_select 'datestamp', item_creation_time
          item[:member_of_paths].each do |set|
            assert_select 'setSpec', set.tr('/', ':')
          end
        end
      end
    end
  end

  def test_list_identifiers_thesis_from_until_date_xml
    thesis = Oaisys::Engine.config.oai_etdms_model.public_items.belongs_to_path(@community.id).first
    thesis_creation_time = thesis[:record_created_at].utc.xmlschema
    just_after_thesis_creation_time = (thesis[:record_created_at] + 5.seconds).utc.xmlschema
    get oaisys_path(verb: 'ListIdentifiers', metadataPrefix: 'oai_etdms', set: @community.id,
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
          assert_select 'identifier', 'oai:era.library.ualberta.ca:' + thesis[:id]
          assert_select 'datestamp', thesis_creation_time
          thesis[:member_of_paths].each do |set|
            assert_select 'setSpec', set.tr('/', ':')
          end
        end
      end
    end
  end

end
