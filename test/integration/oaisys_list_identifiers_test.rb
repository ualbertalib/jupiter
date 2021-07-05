require 'test_helper'

class OaisysListIdentifiersTest < ActionDispatch::IntegrationTest

  include Oaisys::Engine.routes.url_helpers

  setup do
    @routes = Oaisys::Engine.routes
    Oaisys::Engine.config.items_per_request = 2

    @community = communities(:community_fancy)
    @collection = collections(:collection_fancy)

    @thesis_collection = collections(:collection_thesis)
    @embargoed_thesis_collection = collections(:collection_embargoed)
  end

  # rubocop:disable Minitest/MultipleAssertions
  # TODO: our tests are quite smelly.  This one needs work!
  test 'list identifers items xml' do
    # TODO: Add tests for this which uses post requests.
    skip('Skipping until bug regarding path helper is fixed. https://github.com/rails/rails/issues/40078')
    get oaisys_path(verb: 'ListIdentifiers', metadataPrefix: 'oai_dc'), headers: { 'Accept' => 'application/xml' }
    assert_response :success

    assert_valid_against_schema

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
                     owner_id: users(:user_admin).id, title: 'Fancy Item 1',
                     creators: ['Joe Blow'],
                     created: '1938-01-02',
                     languages: [ControlledVocabulary.era.language.english],
                     item_type: ControlledVocabulary.era.item_type.article,
                     publication_status:
                       [ControlledVocabulary.era.publication_status.published],
                     license: ControlledVocabulary.era.license.attribution_4_0_international,
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
  # rubocop:enable Minitest/MultipleAssertions

  test 'list identifers theses xml' do
    get oaisys_path(verb: 'ListIdentifiers', metadataPrefix: 'oai_etdms'), headers: { 'Accept' => 'application/xml' }

    list_identifiers_theses_xml
  end

  test 'list identifers theses xml post' do
    post oaisys_path, params: { verb: 'ListIdentifiers', metadataPrefix: 'oai_etdms' },
                      headers: { 'Content-Type' => 'application/x-www-form-urlencoded', 'Content-Length' => 82 }

    list_identifiers_theses_xml
  end

  test 'list identifers item set xml' do
    get oaisys_path(verb: 'ListIdentifiers', metadataPrefix: 'oai_dc', set: @collection.id),
        headers: { 'Accept' => 'application/xml' }

    list_identifiers_item_set_xml
  end

  test 'list identifers item set xml post' do
    post oaisys_path, params: { verb: 'ListIdentifiers', metadataPrefix: 'oai_dc', set: @collection.id },
                      headers: { 'Accept' => 'application/xml' }

    list_identifiers_item_set_xml
  end

  test 'list identifers thesis set xml' do
    get oaisys_path(verb: 'ListIdentifiers', metadataPrefix: 'oai_etdms', set: @thesis_collection.id),
        headers: { 'Accept' => 'application/xml' }

    list_identifiers_thesis_set_xml
  end

  test 'list identifers thesis set xml post' do
    post oaisys_path, params: { verb: 'ListIdentifiers', metadataPrefix: 'oai_etdms', set: @thesis_collection.id },
                      headers: { 'Accept' => 'application/xml' }

    list_identifiers_thesis_set_xml
  end

  test 'list identifers embargo thesis xml' do
    get oaisys_path(verb: 'ListIdentifiers', metadataPrefix: 'oai_etdms', set: @embargoed_thesis_collection.id),
        headers: { 'Accept' => 'application/xml' }

    assert_no_records_found_response
  end

  test 'list identifers embargo thesis xml post' do
    post oaisys_path, params: { verb: 'ListIdentifiers', metadataPrefix: 'oai_etdms',
                                set: @embargoed_thesis_collection.id },
                      headers: { 'Accept' => 'application/xml' }

    assert_no_records_found_response
  end

  test 'list identifers item until date xml' do
    just_after_current_time = (Time.current + 5).utc.xmlschema
    get oaisys_path(verb: 'ListIdentifiers', metadataPrefix: 'oai_dc', set: @community.id,
                    until: just_after_current_time), headers: { 'Accept' => 'application/xml' }

    list_identifiers_item_until_date_xml(just_after_current_time)
  end

  test 'list identifers item until date xml post' do
    just_after_current_time = (Time.current + 5).utc.xmlschema
    post oaisys_path, params: { verb: 'ListIdentifiers', metadataPrefix: 'oai_dc', set: @community.id,
                                until: just_after_current_time },
                      headers: { 'Content-Type' => 'application/x-www-form-urlencoded', 'Content-Length' => 82 }

    list_identifiers_item_until_date_xml(just_after_current_time)
  end

  test 'list identifers thesis until date xml' do
    just_after_current_time = (Time.current + 5).utc.xmlschema
    get oaisys_path(verb: 'ListIdentifiers', metadataPrefix: 'oai_etdms', set: @thesis_collection.id,
                    until: just_after_current_time), headers: { 'Accept' => 'application/xml' }

    list_identifiers_thesis_until_date_xml(just_after_current_time)
  end

  test 'list identifers thesis until date xml post' do
    just_after_current_time = (Time.current + 5).utc.xmlschema
    post oaisys_path, params: { verb: 'ListIdentifiers', metadataPrefix: 'oai_etdms', set: @thesis_collection.id,
                                until: just_after_current_time },
                      headers: { 'Content-Type' => 'application/x-www-form-urlencoded', 'Content-Length' => 82 }

    list_identifiers_thesis_until_date_xml(just_after_current_time)
  end

  test 'list identifers thesis until date yyyy/mm/dd xml' do
    current_date = Time.current.strftime('%Y-%m-%d')
    get oaisys_path(verb: 'ListIdentifiers', metadataPrefix: 'oai_etdms', set: @thesis_collection.id,
                    until: current_date), headers: { 'Accept' => 'application/xml' }

    list_identifiers_thesis_until_date_yyy_mm_dd_xml(current_date)
  end

  test 'list identifers thesis until date yyyy/mm/dd xml post' do
    current_date = Time.current.strftime('%Y-%m-%d')
    post oaisys_path, params: { verb: 'ListIdentifiers', metadataPrefix: 'oai_etdms', set: @thesis_collection.id,
                                until: current_date }, headers: { 'Content-Type' => 'application/x-www-form-urlencoded',
                                                                  'Content-Length' => 82 }

    list_identifiers_thesis_until_date_yyy_mm_dd_xml(current_date)
  end

  test 'list identifers item from date xml' do
    six_days_from_now = (Time.current + 6.days).strftime('%Y-%m-%d')
    get oaisys_path(verb: 'ListIdentifiers', metadataPrefix: 'oai_dc', set: @community.id,
                    from: six_days_from_now), headers: { 'Accept' => 'application/xml' }

    assert_no_records_found_response
  end

  test 'list identifers item from date xml post' do
    six_days_from_now = (Time.current + 6.days).strftime('%Y-%m-%d')
    post oaisys_path, params: { verb: 'ListIdentifiers', metadataPrefix: 'oai_dc', set: @community.id,
                                from: six_days_from_now },
                      headers: { 'Content-Type' => 'application/x-www-form-urlencoded', 'Content-Length' => 82 }

    assert_no_records_found_response
  end

  test 'list identifers item from date yyy_mm_dd xml' do
    six_days_from_now = (Time.current + 6.days).utc.xmlschema
    get oaisys_path(verb: 'ListIdentifiers', metadataPrefix: 'oai_dc', set: @community.id,
                    from: six_days_from_now), headers: { 'Accept' => 'application/xml' }

    assert_no_records_found_response
  end

  test 'list identifers item from date yyy_mm_dd xml post' do
    six_days_from_now = (Time.current + 6.days).utc.xmlschema
    post oaisys_path, params: { verb: 'ListIdentifiers', metadataPrefix: 'oai_dc', set: @community.id,
                                from: six_days_from_now },
                      headers: { 'Content-Type' => 'application/x-www-form-urlencoded', 'Content-Length' => 82 }

    assert_no_records_found_response
  end

  test 'list identifers thesis from date xml' do
    six_days_from_now = (Time.current + 5).utc.xmlschema
    get oaisys_path(verb: 'ListIdentifiers', metadataPrefix: 'oai_etdms', set: @thesis_collection.id,
                    from: six_days_from_now), headers: { 'Accept' => 'application/xml' }

    assert_no_records_found_response
  end

  test 'list identifers thesis from date xml post' do
    six_days_from_now = (Time.current + 5).utc.xmlschema
    post oaisys_path, params: { verb: 'ListIdentifiers', metadataPrefix: 'oai_etdms', set: @thesis_collection.id,
                                from: six_days_from_now },
                      headers: { 'Content-Type' => 'application/x-www-form-urlencoded', 'Content-Length' => 82 }

    assert_no_records_found_response
  end

  test 'list identifers item from until date xml' do
    item = Oaisys::Engine.config.oai_dc_model.public_items.belongs_to_path(@community.id).first
    item_creation_time = item[:updated_at].utc.xmlschema
    just_after_item_creation_time = (item[:updated_at] + 5.seconds).utc.xmlschema
    get oaisys_path(verb: 'ListIdentifiers', metadataPrefix: 'oai_dc', set: @community.id, from: item_creation_time,
                    until: just_after_item_creation_time),
        headers: { 'Accept' => 'application/xml' }

    assert_item_is_displayed(item, item_creation_time)
  end

  test 'list identifers item from until date xml post' do
    item = Oaisys::Engine.config.oai_dc_model.public_items.belongs_to_path(@community.id).first
    item_creation_time = item[:updated_at].utc.xmlschema
    just_after_item_creation_time = (item[:updated_at] + 5.seconds).utc.xmlschema
    post oaisys_path, params: { verb: 'ListIdentifiers', metadataPrefix: 'oai_dc', set: @community.id,
                                from: item_creation_time, until: just_after_item_creation_time },
                      headers: { 'Accept' => 'application/xml' }

    assert_item_is_displayed(item, item_creation_time)
  end

  test 'list identifers thesis from until date xml' do
    thesis = Oaisys::Engine.config.oai_etdms_model.public_items.belongs_to_path(@thesis_collection.id).first
    thesis_creation_time = thesis[:updated_at].utc.xmlschema
    just_after_thesis_creation_time = (thesis[:updated_at] + 5.seconds).utc.xmlschema
    get oaisys_path(verb: 'ListIdentifiers', metadataPrefix: 'oai_etdms', set: @thesis_collection.id,
                    from: thesis_creation_time, until: just_after_thesis_creation_time),
        headers: { 'Accept' => 'application/xml' }

    assert_item_is_displayed(thesis, thesis_creation_time)
  end

  test 'list identifers thesis from until date xml post' do
    thesis = Oaisys::Engine.config.oai_etdms_model.public_items.belongs_to_path(@thesis_collection.id).first
    thesis_creation_time = thesis[:updated_at].utc.xmlschema
    just_after_thesis_creation_time = (thesis[:updated_at] + 5.seconds).utc.xmlschema
    post oaisys_path, params: { verb: 'ListIdentifiers', metadataPrefix: 'oai_etdms', set: @thesis_collection.id,
                                from: thesis_creation_time, until: just_after_thesis_creation_time },
                      headers: { 'Accept' => 'application/xml' }

    assert_item_is_displayed(thesis, thesis_creation_time)
  end

  test 'list identifers thesis from until date yyy_mm_dd xml' do
    thesis = Oaisys::Engine.config.oai_etdms_model.public_items.belongs_to_path(@thesis_collection.id).first
    thesis_creation_time = thesis[:updated_at].strftime('%Y-%m-%d')
    thesis_creation_time_utc = thesis[:updated_at].utc.xmlschema
    just_after_thesis_creation_time = (thesis[:updated_at] + 5.seconds).strftime('%Y-%m-%d')
    get oaisys_path(verb: 'ListIdentifiers', metadataPrefix: 'oai_etdms', set: @thesis_collection.id,
                    from: thesis_creation_time, until: just_after_thesis_creation_time),
        headers: { 'Accept' => 'application/xml' }

    assert_item_is_displayed(thesis, thesis_creation_time_utc)
  end

  test 'list identifers thesis from until date yyy_mm_dd xml post' do
    thesis = Oaisys::Engine.config.oai_etdms_model.public_items.belongs_to_path(@thesis_collection.id).first
    thesis_creation_time = thesis[:updated_at].strftime('%Y-%m-%d')
    thesis_creation_time_utc = thesis[:updated_at].utc.xmlschema
    just_after_thesis_creation_time = (thesis[:updated_at] + 5.seconds).strftime('%Y-%m-%d')
    post oaisys_path, params: { verb: 'ListIdentifiers', metadataPrefix: 'oai_etdms', set: @thesis_collection.id,
                                from: thesis_creation_time, until: just_after_thesis_creation_time },
                      headers: { 'Accept' => 'application/xml' }

    assert_item_is_displayed(thesis, thesis_creation_time_utc)
  end

  test 'list identifers item invalid from date xml' do
    get oaisys_path(verb: 'ListIdentifiers', metadataPrefix: 'oai_dc', set: @community.id,
                    from: 'junk'), headers: { 'Accept' => 'application/xml' }
    assert_response :success

    assert_bad_argument_response
  end

  test 'list identifers item invalid from date xml post' do
    post oaisys_path, params: { verb: 'ListIdentifiers', metadataPrefix: 'oai_dc', set: @community.id,
                                from: 'junk' }, headers: { 'Content-Type' => 'application/x-www-form-urlencoded',
                                                           'Content-Length' => 82 }
    assert_response :success

    assert_bad_argument_response
  end

  test 'list identifers item invalid until date xml' do
    get oaisys_path(verb: 'ListIdentifiers', metadataPrefix: 'oai_dc', set: @community.id,
                    until: 'junk'), headers: { 'Accept' => 'application/xml' }
    assert_response :success

    assert_bad_argument_response
  end

  test 'list identifers item invalid until date xml post' do
    post oaisys_path, params: { verb: 'ListIdentifiers', metadataPrefix: 'oai_dc', set: @community.id,
                                until: 'junk' }, headers: { 'Content-Type' => 'application/x-www-form-urlencoded',
                                                            'Content-Length' => 82 }
    assert_response :success

    assert_bad_argument_response
  end

  test 'list identifers item invalid from until date xml' do
    get oaisys_path(verb: 'ListIdentifiers', metadataPrefix: 'oai_dc', set: @community.id,
                    from: 'junk', until: 'junk'), headers: { 'Accept' => 'application/xml' }
    assert_response :success

    assert_bad_argument_response
  end

  test 'list identifers item invalid from until date xml post' do
    post oaisys_path, params: { verb: 'ListIdentifiers', metadataPrefix: 'oai_dc', set: @community.id, from: 'junk',
                                until: 'junk' }, headers: { 'Content-Type' => 'application/x-www-form-urlencoded',
                                                            'Content-Length' => 82 }
    assert_response :success

    assert_bad_argument_response
  end

  test 'list identifers item different granularities from until date xml' do
    item = Oaisys::Engine.config.oai_dc_model.public_items.belongs_to_path(@community.id).first
    just_after_item_creation_time = (item[:updated_at] + 5.seconds).utc.xmlschema
    get oaisys_path(verb: 'ListIdentifiers', metadataPrefix: 'oai_dc', set: @community.id, from: '1000/01/01',
                    until: just_after_item_creation_time),
        headers: { 'Accept' => 'application/xml' }

    assert_bad_argument_response
  end

  test 'list identifers item different granularities from until date post xml' do
    item = Oaisys::Engine.config.oai_dc_model.public_items.belongs_to_path(@community.id).first
    just_after_item_creation_time = (item[:updated_at] + 5.seconds).utc.xmlschema
    post oaisys_path, params: { verb: 'ListIdentifiers', metadataPrefix: 'oai_dc', set: @community.id,
                                from: '1000/01/01', until: just_after_item_creation_time },
                      headers: { 'Accept' => 'application/xml' }

    assert_bad_argument_response
  end

  private

  def list_identifiers_item_until_date_xml(just_after_current_time)
    assert_valid_against_schema

    item_identifiers = Oaisys::Engine.config.oai_dc_model.public_items.updated_before(just_after_current_time)
                                     .limit(Oaisys::Engine.config.items_per_request)
                                     .belongs_to_path(@community.id).pluck(:id, :updated_at, :member_of_paths)

    assert_identifiers_response(item_identifiers)
  end

  def list_identifiers_thesis_set_xml
    assert_valid_against_schema

    thesis_identifiers = Oaisys::Engine.config.oai_etdms_model.public_items.belongs_to_path(@thesis_collection.id)
                                       .limit(Oaisys::Engine.config.items_per_request)
                                       .pluck(:id, :updated_at, :member_of_paths)

    assert_identifiers_response(thesis_identifiers)
  end

  def list_identifiers_thesis_until_date_yyy_mm_dd_xml(current_date)
    assert_valid_against_schema

    thesis_identifiers = Oaisys::Engine.config.oai_etdms_model
                                       .public_items.updated_before(current_date)
                                       .belongs_to_path(@thesis_collection.id)
                                       .limit(Oaisys::Engine.config.items_per_request)
                                       .pluck(:id, :updated_at, :member_of_paths)

    assert_identifiers_response(thesis_identifiers)
  end

  def assert_item_is_displayed(item, item_creation_time)
    assert_valid_against_schema

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

  def list_identifiers_thesis_until_date_xml(just_after_current_time)
    assert_valid_against_schema

    thesis_identifiers = Oaisys::Engine.config.oai_etdms_model
                                       .public_items.updated_before(just_after_current_time)
                                       .belongs_to_path(@thesis_collection.id)
                                       .limit(Oaisys::Engine.config.items_per_request)
                                       .pluck(:id, :updated_at, :member_of_paths)
    assert_identifiers_response(thesis_identifiers)
  end

  def list_identifiers_theses_xml
    assert_valid_against_schema

    thesis_identifiers = Oaisys::Engine.config.oai_etdms_model.public_items
                                       .limit(Oaisys::Engine.config.items_per_request)
                                       .pluck(:id, :updated_at, :member_of_paths)
    assert_identifiers_response(thesis_identifiers)
  end

  def list_identifiers_item_set_xml
    assert_valid_against_schema

    item_identifiers = Oaisys::Engine.config.oai_dc_model.public_items.belongs_to_path(@collection.id)
                                     .limit(Oaisys::Engine.config.items_per_request)
                                     .pluck(:id, :updated_at, :member_of_paths)
    assert_identifiers_response(item_identifiers)
  end

  def assert_no_records_found_response
    assert_valid_against_schema

    assert_select 'OAI-PMH' do
      assert_select 'responseDate'
      assert_select 'request'
      assert_select 'error', I18n.t('error_messages.no_record_found')
    end
  end

  def assert_bad_argument_response
    assert_valid_against_schema

    assert_select 'OAI-PMH' do
      assert_select 'responseDate'
      assert_select 'request'
      assert_select 'error', I18n.t('error_messages.illegal_or_missing_arguments')
    end
  end

  def assert_valid_against_schema
    assert_response :success

    schema = Nokogiri::XML::Schema(File.open(file_fixture('OAI-PMH.xsd')), Nokogiri::XML::ParseOptions.new.nononet)
    document = Nokogiri::XML(@response.body)
    assert_empty schema.validate(document)
  end

  def assert_identifiers_response(identifiers)
    assert_select 'OAI-PMH' do
      assert_select 'responseDate'
      assert_select 'request'
      assert_select 'ListIdentifiers' do
        identifiers.each do |identifier, date, sets|
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

end
