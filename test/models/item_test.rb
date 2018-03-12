require 'test_helper'

class ItemTest < ActiveSupport::TestCase

  test 'a valid item can be constructed' do
    community = Community.new_locked_ldp_object(title: 'Community', owner: 1,
                                                visibility: JupiterCore::VISIBILITY_PUBLIC)
    community.unlock_and_fetch_ldp_object(&:save!)
    collection = Collection.new_locked_ldp_object(title: 'Collection', owner: 1,
                                                  visibility: JupiterCore::VISIBILITY_PUBLIC,
                                                  community_id: community.id)
    collection.unlock_and_fetch_ldp_object(&:save!)
    item = Item.new_locked_ldp_object(title: 'Item', owner: 1, visibility: JupiterCore::VISIBILITY_PUBLIC,
                                      created: '2017-02-02',
                                      languages: [CONTROLLED_VOCABULARIES[:language].english],
                                      creators: ['Joe Blow'],
                                      subject: ['Things'],
                                      license: CONTROLLED_VOCABULARIES[:license].attribution_4_0_international,
                                      item_type: CONTROLLED_VOCABULARIES[:item_type].article,
                                      publication_status: [CONTROLLED_VOCABULARIES[:publication_status].draft,
                                                           CONTROLLED_VOCABULARIES[:publication_status].submitted])
    assert_difference -> { Item.public.count } do
      item.unlock_and_fetch_ldp_object do |unlocked_item|
        unlocked_item.add_to_path(community.id, collection.id)
        unlocked_item.save!
      end
    end
    assert item.valid?
    assert_equal item.id, Item.public.first.id
    item.unlock_and_fetch_ldp_object(&:destroy)
  end

  test 'there is no default visibility' do
    item = Item.new_locked_ldp_object

    assert_nil item.visibility
  end

  test 'unknown visibilities are not valid' do
    item = Item.new_locked_ldp_object

    item.unlock_and_fetch_ldp_object do |unlocked_item|
      unlocked_item.visibility = 'some_fake_visibility'
    end

    assert_not item.valid?
    assert item.errors[:visibility].present?
    assert_includes item.errors[:visibility], 'some_fake_visibility is not a known visibility'
  end

  test 'embargo is a valid visibility for items' do
    assert_includes Item.valid_visibilities, Item::VISIBILITY_EMBARGO
  end

  test 'created allows fuzzy dates' do
    item = Item.new_locked_ldp_object
    assert_nothing_raised do
      item.unlock_and_fetch_ldp_object do |unlocked_item|
        unlocked_item.created = 'before 1997 or after 2084'
      end
    end
    assert_not item.valid?
    assert_equal '1997', item.sort_year
  end

  test 'embargo_end_date must be present if visibility is embargo' do
    item = Item.new_locked_ldp_object
    item.unlock_and_fetch_ldp_object do |unlocked_item|
      unlocked_item.visibility = Item::VISIBILITY_EMBARGO
    end

    assert_not item.valid?
    assert item.errors[:embargo_end_date].present?
    assert_includes item.errors[:embargo_end_date], "can't be blank"
  end

  test 'embargo_end_date must be blank for non-embargo visibilities' do
    item = Item.new_locked_ldp_object
    item.unlock_and_fetch_ldp_object do |unlocked_item|
      unlocked_item.visibility = JupiterCore::VISIBILITY_PUBLIC
      unlocked_item.embargo_end_date = '1992-02-01'
    end

    assert_not item.valid?
    assert item.errors[:embargo_end_date].present?
    assert_includes item.errors[:embargo_end_date], 'must be blank'

    refute item.errors[:visibility].present?
  end

  test 'visibility_after_embargo must be present if visibility is embargo' do
    item = Item.new_locked_ldp_object
    item.unlock_and_fetch_ldp_object do |unlocked_item|
      unlocked_item.visibility = Item::VISIBILITY_EMBARGO
    end

    assert_not item.valid?
    assert item.errors[:visibility_after_embargo].present?
    assert_includes item.errors[:visibility_after_embargo], "can't be blank"
  end

  test 'visibility_after_embargo must be blank for non-embargo visibilities' do
    item = Item.new_locked_ldp_object
    item.unlock_and_fetch_ldp_object do |unlocked_item|
      unlocked_item.visibility = JupiterCore::VISIBILITY_PUBLIC
      unlocked_item.visibility_after_embargo = CONTROLLED_VOCABULARIES[:visibility].draft
    end

    assert_not item.valid?
    assert item.errors[:visibility_after_embargo].present?
    assert_includes item.errors[:visibility_after_embargo], 'must be blank'
    # Make sure no controlled vocabulary error
    refute_includes item.errors[:visibility_after_embargo], 'is not recognized'

    refute item.errors[:visibility].present?
  end

  test 'visibility_after_embargo must be from the controlled vocabulary' do
    item = Item.new_locked_ldp_object
    item.unlock_and_fetch_ldp_object do |unlocked_item|
      unlocked_item.visibility = Item::VISIBILITY_EMBARGO
      unlocked_item.visibility_after_embargo = 'whatever'
    end

    assert_not item.valid?
    assert item.errors[:visibility_after_embargo].present?
    assert_includes item.errors[:visibility_after_embargo], 'is not recognized'
    refute item.errors[:visibility].present?
  end

  test '#add_to_path assigns paths properly' do
    item = Item.new_locked_ldp_object
    community_id = generate_random_string
    collection_id = generate_random_string

    item.unlock_and_fetch_ldp_object do |unlocked_item|
      unlocked_item.add_to_path(community_id, collection_id)
    end

    assert_includes item.member_of_paths, "#{community_id}/#{collection_id}"
  end

  test 'member_of_paths is not a display attribute' do
    assert_not_includes Item.display_attribute_names, :member_of_paths
  end

  test 'a community/collection path must be present' do
    item = Item.new_locked_ldp_object

    assert_not item.valid?
    assert_includes item.errors[:member_of_paths], "can't be blank"
  end

  test 'community/collection must exist' do
    item = Item.new_locked_ldp_object
    community_id = generate_random_string
    collection_id = generate_random_string
    item.unlock_and_fetch_ldp_object do |unlocked|
      unlocked.add_to_path(community_id, collection_id)
    end

    assert_not item.valid?
    assert_includes item.errors[:member_of_paths],
                    I18n.t('activemodel.errors.models.ir_item.attributes.member_of_paths.community_not_found',
                           id: community_id)
    assert_includes item.errors[:member_of_paths],
                    I18n.t('activemodel.errors.models.ir_item.attributes.member_of_paths.collection_not_found',
                           id: collection_id)
  end

  test 'a language must be present' do
    item = Item.new_locked_ldp_object

    assert_not item.valid?
    assert_includes item.errors[:languages], "can't be blank"
  end

  test 'a language must be from the controlled vocabulary' do
    item = Item.new_locked_ldp_object(languages: ['whatever'])
    assert_not item.valid?
    assert_includes item.errors[:languages], 'is not recognized'

    item = Item.new_locked_ldp_object(languages: [CONTROLLED_VOCABULARIES[:language].english])
    assert_not item.valid?
    refute_includes item.errors.keys, :languages
  end

  test 'a license or rights statement must be present' do
    item = Item.new_locked_ldp_object

    assert_not item.valid?
    assert_includes item.errors[:base], 'must have either a license or a rights statement'
  end

  test 'a rights statement must not be present if a license is present' do
    item = Item.new_locked_ldp_object(rights: 'Share my work with everybody',
                                      license: CONTROLLED_VOCABULARIES[:license].attribution_4_0_international)

    assert_not item.valid?
    assert_includes item.errors[:base], 'should not have both a license and a rights statement'
  end

  test 'a license must be either from the controlled vocabulary for new licenses or for old licenses' do
    item = Item.new_locked_ldp_object(license: 'whatever')
    assert_not item.valid?
    assert_includes item.errors[:license], 'is not recognized'

    item = Item.new_locked_ldp_object(license: CONTROLLED_VOCABULARIES[:license].attribution_4_0_international)
    item.valid?
    refute_includes item.errors.keys, :license

    item = Item.new_locked_ldp_object(license: CONTROLLED_VOCABULARIES[:old_license].attribution_3_0_international)
    item.valid?
    refute_includes item.errors.keys, :license
  end

  test 'an item type is required' do
    item = Item.new_locked_ldp_object
    assert_not item.valid?
    assert_includes item.errors[:item_type], "can't be blank"
  end

  test 'an item type must come from the controlled vocabulary' do
    item = Item.new_locked_ldp_object(item_type: 'whatever')
    assert_not item.valid?
    assert_includes item.errors[:item_type], 'is not recognized'
  end

  test 'publication status is needed for articles' do
    item = Item.new_locked_ldp_object(item_type: CONTROLLED_VOCABULARIES[:item_type].article)
    assert_not item.valid?
    assert_includes item.errors[:publication_status], 'is required for articles'
  end

  test 'publication status must come from controlled vocabulary' do
    item = Item.new_locked_ldp_object(item_type: CONTROLLED_VOCABULARIES[:item_type].article,
                                      publication_status: ['whatever'])
    assert_not item.valid?
    assert_includes item.errors[:publication_status], 'is not recognized'
  end

  test 'publication status must either be published or both draft/submitted' do
    item = Item.new_locked_ldp_object(item_type: CONTROLLED_VOCABULARIES[:item_type].article,
                                      publication_status: [CONTROLLED_VOCABULARIES[:publication_status].published])
    item.valid?
    refute item.errors[:publication_status].present?

    item = Item.new_locked_ldp_object(item_type: CONTROLLED_VOCABULARIES[:item_type].article,
                                      publication_status: [CONTROLLED_VOCABULARIES[:publication_status].draft,
                                                           CONTROLLED_VOCABULARIES[:publication_status].submitted])
    item.valid?
    refute item.errors[:publication_status].present?

    item = Item.new_locked_ldp_object(item_type: CONTROLLED_VOCABULARIES[:item_type].article,
                                      publication_status: [CONTROLLED_VOCABULARIES[:publication_status].draft])
    item.valid?
    assert_includes item.errors[:publication_status], 'is not recognized'

    item = Item.new_locked_ldp_object(item_type: CONTROLLED_VOCABULARIES[:item_type].article,
                                      publication_status: [CONTROLLED_VOCABULARIES[:publication_status].submitted])
    item.valid?
    assert_includes item.errors[:publication_status], 'is not recognized'
  end

  test 'publication status must be absent for non-articles' do
    item = Item.new_locked_ldp_object(item_type: CONTROLLED_VOCABULARIES[:item_type].book,
                                      publication_status: [CONTROLLED_VOCABULARIES[:publication_status].published])
    assert_not item.valid?
    assert_includes item.errors[:publication_status], 'must be absent for non-articles'
  end

  test 'item_type_with_status_code gets set correctly' do
    item = Item.new_locked_ldp_object(item_type: CONTROLLED_VOCABULARIES[:item_type].article,
                                      publication_status: [CONTROLLED_VOCABULARIES[:publication_status].published])
    assert_equal :article_published, item.item_type_with_status_code

    item = Item.new_locked_ldp_object(item_type: CONTROLLED_VOCABULARIES[:item_type].article,
                                      publication_status: [CONTROLLED_VOCABULARIES[:publication_status].draft,
                                                           CONTROLLED_VOCABULARIES[:publication_status].submitted])
    assert_equal :article_submitted, item.item_type_with_status_code

    item = Item.new_locked_ldp_object(item_type: CONTROLLED_VOCABULARIES[:item_type].report)
    assert_equal :report, item.item_type_with_status_code
  end

  test 'a subject is required' do
    item = Item.new_locked_ldp_object
    assert_not item.valid?
    assert_includes item.errors[:subject], "can't be blank"
  end

  test 'a creator is required' do
    item = Item.new_locked_ldp_object
    assert_not item.valid?
    assert_includes item.errors[:creators], "can't be blank"
  end

  test 'created is required' do
    item = Item.new_locked_ldp_object
    assert_not item.valid?
    assert_includes item.errors[:created], "can't be blank"
  end

  test 'sort_year is required' do
    item = Item.new_locked_ldp_object
    assert_not item.valid?
    assert_includes item.errors[:sort_year], "can't be blank"
  end

  test 'sort_year is derived from created' do
    item = Item.new_locked_ldp_object(created: 'Fall 2015')
    item.valid?
    refute item.errors[:sort_year].present?
    assert_equal item.sort_year, '2015'
  end

  test 'add_files maintains correct order and correctly creates list_source proxies' do
    # Doing a lot of I/O with Fedora, so I don't want to break this long test into pieces
    community = Community.new_locked_ldp_object(title: 'Community', owner: 1).unlock_and_fetch_ldp_object(&:save!)
    collection = Collection.new_locked_ldp_object(title: 'foo', owner: users(:regular).id,
                                                  community_id: community.id).unlock_and_fetch_ldp_object(&:save!)

    item = Item.new_locked_ldp_object(title: generate_random_string,
                                      creators: [generate_random_string],
                                      visibility: JupiterCore::VISIBILITY_PUBLIC,
                                      created: '1978-01-01',
                                      owner: 1,
                                      item_type: CONTROLLED_VOCABULARIES[:item_type].report,
                                      languages: [CONTROLLED_VOCABULARIES[:language].english],
                                      license: CONTROLLED_VOCABULARIES[:license].attribution_4_0_international,
                                      subject: ['Randomness'])

    fedora_item_url = nil
    item.unlock_and_fetch_ldp_object do |unlocked_item|
      unlocked_item.add_to_path(community.id, collection.id)
      unlocked_item.save!
      fedora_item_url = unlocked_item.uri

      File.open(file_fixture('image-sample.jpeg'), 'r') do |file1|
        File.open(file_fixture('pdf-sample.pdf'), 'r') do |file2|
          File.open(file_fixture('text-sample.txt'), 'r') do |file3|
            unlocked_item.add_files([file1, file2, file3])
          end
        end
      end
      unlocked_item.save!
      assert_equal unlocked_item.ordered_members.to_a.map(&:contained_filename),
                   ['image-sample.jpeg', 'pdf-sample.pdf', 'text-sample.txt']
    end

    # Make sure the list source proxies have been created, and work as expected
    list_source_uri = RDF::URI(fedora_item_url + '/list_source')
    graph = RDF::Graph.load(list_source_uri)
    # `next` is ruby keyword, hence the `iana_*` names
    iana = 'http://www.iana.org/assignments/relation/'
    iana_first = RDF::URI(iana + 'first')
    iana_last = RDF::URI(iana + 'last')
    iana_next = RDF::URI(iana + 'next')
    iana_prev = RDF::URI(iana + 'prev')
    proxy_for = RDF::URI('http://www.openarchives.org/ore/terms/proxyFor')

    list_source_filesets = []
    # Fetch first FileSet in list source
    first_uri = nil
    graph.query(subject: list_source_uri, predicate: iana_first) do |statement|
      # e.g., this uri sort of looks like object_url + '/list_source#g47328166227360'
      first_uri = statement.object
    end
    graph.query(subject: first_uri, predicate: proxy_for) do |statement|
      id = statement.object.to_s.split('/').last
      list_source_filesets.append(FileSet.find(id))
    end
    graph.query(subject: first_uri, predicate: iana_prev) do
      raise 'A previous item should not exist for first fileset'
    end

    # Fetch second FileSet in list source
    second_uri = nil
    graph.query(subject: first_uri, predicate: iana_next) do |statement|
      second_uri = statement.object
    end
    graph.query(subject: second_uri, predicate: proxy_for) do |statement|
      id = statement.object.to_s.split('/').last
      list_source_filesets.append(FileSet.find(id))
    end
    graph.query(subject: second_uri, predicate: iana_prev) do |statement|
      assert_equal statement.object, first_uri
    end

    # Fetch third FileSet in list source
    third_uri = nil
    graph.query(subject: second_uri, predicate: iana_next) do |statement|
      third_uri = statement.object
    end
    graph.query(subject: third_uri, predicate: proxy_for) do |statement|
      id = statement.object.to_s.split('/').last
      list_source_filesets.append(FileSet.find(id))
    end
    graph.query(subject: third_uri, predicate: iana_prev) do |statement|
      assert_equal statement.object, second_uri
    end
    graph.query(subject: third_uri, predicate: iana_next) do
      raise 'A next item should not exist for third fileset'
    end
    graph.query(subject: list_source_uri, predicate: iana_last) do |statement|
      assert_equal statement.object, third_uri
    end
    # Finally, confirm the fetched file sets match the order we expect
    assert_equal list_source_filesets.map(&:contained_filename),
                 ['image-sample.jpeg', 'pdf-sample.pdf', 'text-sample.txt']

    # Adding another file should put it at the end of the ordered list
    item.unlock_and_fetch_ldp_object do |unlocked_item|
      File.open(file_fixture('sitemap.xsd'), 'r') do |file4|
        unlocked_item.add_files([file4])
      end
      assert_equal unlocked_item.ordered_members.to_a.map(&:contained_filename),
                   ['image-sample.jpeg', 'pdf-sample.pdf', 'text-sample.txt', 'sitemap.xsd']
    end
  end

end
