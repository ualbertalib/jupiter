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
    item = Item.new(title: 'Item', owner_id: 1, visibility: JupiterCore::VISIBILITY_PUBLIC,
                                      created: '2017-02-02',
                                      languages: [CONTROLLED_VOCABULARIES[:language].english],
                                      creators: ['Joe Blow'],
                                      subject: ['Things'],
                                      license: CONTROLLED_VOCABULARIES[:license].attribution_4_0_international,
                                      item_type: CONTROLLED_VOCABULARIES[:item_type].article,
                                      publication_status: [CONTROLLED_VOCABULARIES[:publication_status].draft,
                                                           CONTROLLED_VOCABULARIES[:publication_status].submitted])
    assert_difference -> {Item.public_items.count } do
      item.unlock_and_fetch_ldp_object do |unlocked_item|
        unlocked_item.add_to_path(community.id, collection.id)
        unlocked_item.save!
      end
    end
    assert item.valid?
    assert Item.public_items.map(&:id).include?(item.id)

    assert_difference -> {Item.public_items.count }, -1 do
      item.unlock_and_fetch_ldp_object do |unlocked_item|
        unlocked_item.visibility = JupiterCore::VISIBILITY_PRIVATE
        unlocked_item.save!
      end
    end
    assert item.valid?
    assert_not Item.public_items.map(&:id).include?(item.id)
  end

  test 'there is no default visibility' do
    item = Item.new

    assert_nil item.visibility
  end

  test 'unknown visibilities are not valid' do
    item = Item.new

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
    item = Item.new
    assert_nothing_raised do
      item.unlock_and_fetch_ldp_object do |unlocked_item|
        unlocked_item.created = 'before 1997 or after 2084'
      end
    end
    assert_not item.valid?
    assert_equal 1997, item.sort_year
  end

  test 'embargo_end_date must be present if visibility is embargo' do
    item = Item.new
    item.unlock_and_fetch_ldp_object do |unlocked_item|
      unlocked_item.visibility = Item::VISIBILITY_EMBARGO
    end

    assert_not item.valid?
    assert item.errors[:embargo_end_date].present?
    assert_includes item.errors[:embargo_end_date], "can't be blank"
  end

  test 'embargo_end_date must be blank for non-embargo visibilities' do
    item = Item.new
    item.unlock_and_fetch_ldp_object do |unlocked_item|
      unlocked_item.visibility = JupiterCore::VISIBILITY_PUBLIC
      unlocked_item.embargo_end_date = '1992-02-01'
    end

    assert_not item.valid?
    assert item.errors[:embargo_end_date].present?
    assert_includes item.errors[:embargo_end_date], 'must be blank'

    assert_not item.errors[:visibility].present?
  end

  test 'visibility_after_embargo must be present if visibility is embargo' do
    item = Item.new
    item.unlock_and_fetch_ldp_object do |unlocked_item|
      unlocked_item.visibility = Item::VISIBILITY_EMBARGO
    end

    assert_not item.valid?
    assert item.errors[:visibility_after_embargo].present?
    assert_includes item.errors[:visibility_after_embargo], "can't be blank"
  end

  test 'visibility_after_embargo must be blank for non-embargo visibilities' do
    item = Item.new
    item.unlock_and_fetch_ldp_object do |unlocked_item|
      unlocked_item.visibility = JupiterCore::VISIBILITY_PUBLIC
      unlocked_item.visibility_after_embargo = CONTROLLED_VOCABULARIES[:visibility].draft
    end

    assert_not item.valid?
    assert item.errors[:visibility_after_embargo].present?
    assert_includes item.errors[:visibility_after_embargo], 'must be blank'
    # Make sure no controlled vocabulary error
    assert_not_includes item.errors[:visibility_after_embargo], 'is not recognized'

    assert_not item.errors[:visibility].present?
  end

  test 'visibility_after_embargo must be from the controlled vocabulary' do
    item = Item.new
    item.unlock_and_fetch_ldp_object do |unlocked_item|
      unlocked_item.visibility = Item::VISIBILITY_EMBARGO
      unlocked_item.visibility_after_embargo = 'whatever'
    end

    assert_not item.valid?
    assert item.errors[:visibility_after_embargo].present?
    assert_includes item.errors[:visibility_after_embargo], 'is not recognized'
    assert_not item.errors[:visibility].present?
  end

  test '#add_to_path assigns paths properly' do
    item = Item.new
    community_id = generate_random_string
    collection_id = generate_random_string

    item.unlock_and_fetch_ldp_object do |unlocked_item|
      unlocked_item.add_to_path(community_id, collection_id)
    end

    assert_includes item.member_of_paths, "#{community_id}/#{collection_id}"
  end

  test 'a community/collection path must be present' do
    item = Item.new

    assert_not item.valid?
    assert_includes item.errors[:member_of_paths], "can't be blank"
  end

  test 'community/collection must exist' do
    item = Item.new
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
    item = Item.new

    assert_not item.valid?
    assert_includes item.errors[:languages], "can't be blank"
  end

  test 'a language must be from the controlled vocabulary' do
    item = Item.new(languages: ['whatever'])
    assert_not item.valid?
    assert_includes item.errors[:languages], 'is not recognized'

    item = Item.new(languages: [CONTROLLED_VOCABULARIES[:language].english])
    assert_not item.valid?
    assert_not_includes item.errors.keys, :languages
  end

  test 'a license or rights statement must be present' do
    item = Item.new

    assert_not item.valid?
    assert_includes item.errors[:base], 'must have either a license or a rights statement'
  end

  test 'a rights statement must not be present if a license is present' do
    item = Item.new(rights: 'Share my work with everybody',
                                      license: CONTROLLED_VOCABULARIES[:license].attribution_4_0_international)

    assert_not item.valid?
    assert_includes item.errors[:base], 'should not have both a license and a rights statement'
  end

  test 'a license must be either from the controlled vocabulary for new licenses or for old licenses' do
    item = Item.new(license: 'whatever')
    assert_not item.valid?
    assert_includes item.errors[:license], 'is not recognized'

    item = Item.new(license: CONTROLLED_VOCABULARIES[:license].attribution_4_0_international)
    item.valid?
    assert_not_includes item.errors.keys, :license

    item = Item.new(license: CONTROLLED_VOCABULARIES[:old_license].attribution_3_0_international)
    item.valid?
    assert_not_includes item.errors.keys, :license
  end

  test 'an item type is required' do
    item = Item.new
    assert_not item.valid?
    assert_includes item.errors[:item_type], "can't be blank"
  end

  test 'an item type must come from the controlled vocabulary' do
    item = Item.new(item_type: 'whatever')
    assert_not item.valid?
    assert_includes item.errors[:item_type], 'is not recognized'
  end

  test 'publication status is needed for articles' do
    item = Item.new(item_type: CONTROLLED_VOCABULARIES[:item_type].article)
    assert_not item.valid?
    assert_includes item.errors[:publication_status], 'is required for articles'
  end

  test 'publication status must come from controlled vocabulary' do
    item = Item.new(item_type: CONTROLLED_VOCABULARIES[:item_type].article,
                                      publication_status: ['whatever'])
    assert_not item.valid?
    assert_includes item.errors[:publication_status], 'is not recognized'
  end

  test 'publication status must either be published or both draft/submitted' do
    item = Item.new(item_type: CONTROLLED_VOCABULARIES[:item_type].article,
                                      publication_status: [CONTROLLED_VOCABULARIES[:publication_status].published])
    item.valid?
    assert_not item.errors[:publication_status].present?

    item = Item.new(item_type: CONTROLLED_VOCABULARIES[:item_type].article,
                                      publication_status: [CONTROLLED_VOCABULARIES[:publication_status].draft,
                                                           CONTROLLED_VOCABULARIES[:publication_status].submitted])
    item.valid?
    assert_not item.errors[:publication_status].present?

    item = Item.new(item_type: CONTROLLED_VOCABULARIES[:item_type].article,
                                      publication_status: [CONTROLLED_VOCABULARIES[:publication_status].draft])
    item.valid?
    assert_includes item.errors[:publication_status], 'is not recognized'

    item = Item.new(item_type: CONTROLLED_VOCABULARIES[:item_type].article,
                                      publication_status: [CONTROLLED_VOCABULARIES[:publication_status].submitted])
    item.valid?
    assert_includes item.errors[:publication_status], 'is not recognized'
  end

  test 'publication status must be absent for non-articles' do
    item = Item.new(item_type: CONTROLLED_VOCABULARIES[:item_type].book,
                                      publication_status: [CONTROLLED_VOCABULARIES[:publication_status].published])
    assert_not item.valid?
    assert_includes item.errors[:publication_status], 'must be absent for non-articles'
  end

  test 'item_type_with_status_code gets set correctly' do
    item = Item.new(item_type: CONTROLLED_VOCABULARIES[:item_type].article,
                                      publication_status: [CONTROLLED_VOCABULARIES[:publication_status].published])
    assert_equal :article_published, item.item_type_with_status_code

    item = Item.new(item_type: CONTROLLED_VOCABULARIES[:item_type].article,
                                      publication_status: [CONTROLLED_VOCABULARIES[:publication_status].draft,
                                                           CONTROLLED_VOCABULARIES[:publication_status].submitted])
    assert_equal :article_submitted, item.item_type_with_status_code

    item = Item.new(item_type: CONTROLLED_VOCABULARIES[:item_type].report)
    assert_equal :report, item.item_type_with_status_code
  end

  test 'a subject is required' do
    item = Item.new
    assert_not item.valid?
    assert_includes item.errors[:subject], "can't be blank"
  end

  test 'a creator is required' do
    item = Item.new
    assert_not item.valid?
    assert_includes item.errors[:creators], "can't be blank"
  end

  test 'created is required' do
    item = Item.new
    assert_not item.valid?
    assert_includes item.errors[:created], "can't be blank"
  end

  test 'sort_year is required' do
    item = Item.new
    assert_not item.valid?
    assert_includes item.errors[:sort_year], "can't be blank"
  end

  test 'sort_year is derived from created' do
    item = Item.new(created: 'Fall 2015')
    item.valid?
    assert_not item.errors[:sort_year].present?
    assert_equal item.sort_year, 2015
  end

  # Preservation queue handling
  test 'should add id with the correct score for a new item to preservation queue' do
    Redis.current.del Rails.application.secrets.preservation_queue_name

    # Setup an item...
    community = Community.new_locked_ldp_object(title: 'Community', owner: 1).unlock_and_fetch_ldp_object(&:save!)
    collection = Collection.new_locked_ldp_object(title: 'foo', owner: users(:regular).id,
                                                  community_id: community.id).unlock_and_fetch_ldp_object(&:save!)

    item = Item.new(title: generate_random_string,
                                      creators: [generate_random_string],
                                      visibility: JupiterCore::VISIBILITY_PUBLIC,
                                      created: '1978-01-01',
                                      owner_id: 1,
                                      item_type: CONTROLLED_VOCABULARIES[:item_type].report,
                                      languages: [CONTROLLED_VOCABULARIES[:language].english],
                                      license: CONTROLLED_VOCABULARIES[:license].attribution_4_0_international,
                                      subject: ['Randomness'])

    freeze_time do
      item.unlock_and_fetch_ldp_object do |unlocked_item|
        unlocked_item.add_to_path(community.id, collection.id)
        unlocked_item.save
      end

      item_id, score = Redis.current.zrange(Rails.application.secrets.preservation_queue_name,
                                            0,
                                            -1,
                                            with_scores: true)[0]

      assert_equal item.id, item_id
      assert_in_delta 0.5, score, Time.now.to_f
    end

    Redis.current.del Rails.application.secrets.preservation_queue_name
  end

  test 'should end up with the queue only having an item id once after multiple saves of the same item' do
    Redis.current.del Rails.application.secrets.preservation_queue_name

    # Setup an item...
    community = Community.new_locked_ldp_object(title: 'Community', owner: 1).unlock_and_fetch_ldp_object(&:save!)
    collection = Collection.new_locked_ldp_object(title: 'foo', owner: users(:regular).id,
                                                  community_id: community.id).unlock_and_fetch_ldp_object(&:save!)

    item = Item.new(title: generate_random_string,
                                      creators: [generate_random_string],
                                      visibility: JupiterCore::VISIBILITY_PUBLIC,
                                      created: '1978-01-01',
                                      owner_id: 1,
                                      item_type: CONTROLLED_VOCABULARIES[:item_type].report,
                                      languages: [CONTROLLED_VOCABULARIES[:language].english],
                                      license: CONTROLLED_VOCABULARIES[:license].attribution_4_0_international,
                                      subject: ['Randomness'])

    travel 1.minute do
      item.unlock_and_fetch_ldp_object(&:save)
    end

    travel 3.minutes do
      item.unlock_and_fetch_ldp_object(&:save)
    end

    freeze_time do
      item.unlock_and_fetch_ldp_object do |unlocked_item|
        unlocked_item.add_to_path(community.id, collection.id)
        unlocked_item.save
      end

      assert_equal 1, Redis.current.zcard(Rails.application.secrets.preservation_queue_name)

      item_id, score = Redis.current.zrange(Rails.application.secrets.preservation_queue_name,
                                            0,
                                            -1,
                                            with_scores: true)[0]

      assert_equal item.id, item_id
      assert_in_delta 0.5, score, 3.minutes.from_now.to_f
    end

    Redis.current.del Rails.application.secrets.preservation_queue_name
  end

  test 'should end up with item ids in the queue in the correct temporal order' do
    Redis.current.del Rails.application.secrets.preservation_queue_name

    # Setup some items...
    community = Community.new_locked_ldp_object(title: 'Community', owner: 1).unlock_and_fetch_ldp_object(&:save!)
    collection = Collection.new_locked_ldp_object(title: 'foo', owner: users(:regular).id,
                                                  community_id: community.id).unlock_and_fetch_ldp_object(&:save!)
    items = []
    3.times do
      items << Item.new(title: generate_random_string,
                                          creators: [generate_random_string],
                                          visibility: JupiterCore::VISIBILITY_PUBLIC,
                                          created: '1978-01-01',
                                          owner_id: 1,
                                          item_type: CONTROLLED_VOCABULARIES[:item_type].report,
                                          languages: [CONTROLLED_VOCABULARIES[:language].english],
                                          license: CONTROLLED_VOCABULARIES[:license].attribution_4_0_international,
                                          subject: ['Randomness'])
    end

    # this is all maybe a bit too "there's nothing up my sleeve" about item id orders, but c'est la vie
    items = items.shuffle

    freeze_time do
      items[0].unlock_and_fetch_ldp_object do |unlocked_item|
        unlocked_item.add_to_path(community.id, collection.id)
        unlocked_item.save
      end
    end

    travel_to 6.minutes.ago do
      items[1].unlock_and_fetch_ldp_object do |unlocked_item|
        unlocked_item.add_to_path(community.id, collection.id)
        unlocked_item.save
      end
    end

    travel_to 2.hours.from_now do
      items[2].unlock_and_fetch_ldp_object do |unlocked_item|
        unlocked_item.add_to_path(community.id, collection.id)
        unlocked_item.save
      end
    end

    save_order = [items[1], items[0], items[2]]

    queue = Redis.current.zrange(Rails.application.secrets.preservation_queue_name, 0, -1, with_scores: false)
    assert_equal save_order.map(&:id), queue

    Redis.current.del Rails.application.secrets.preservation_queue_name
  end

end
