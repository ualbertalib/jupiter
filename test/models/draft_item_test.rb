require 'test_helper'

class DraftItemTest < ActiveSupport::TestCase

  setup do
    @community = communities(:community_books)
    @collection = collections(:collection_fantasy)
  end

  test 'enums' do
    assert define_enum_for(:status)
    assert define_enum_for(:wizard_step)
    assert define_enum_for(:license)
    assert define_enum_for(:visibility)
    assert define_enum_for(:visibility_after_embargo)
  end

  test 'associations' do
    assert have_many(:draft_items_languages).dependent(:destroy)
    assert have_many(:languages).through(:draft_items_languages)
    assert belong_to(:type)
    assert belong_to(:user)
  end

  test 'should not be able to create a draft item without user' do
    draft_item = DraftItem.new

    assert_not draft_item.valid?
    assert_equal 'User must exist', draft_item.errors.full_messages.first
  end

  test 'should be able to create a draft item with user when on inactive status' do
    user = users(:user_regular)
    draft_item = DraftItem.new(user:)

    assert_predicate draft_item, :valid?
  end

  test 'should run validations when on describe_item step' do
    user = users(:user_regular)
    draft_item = DraftItem.new(user:, status: DraftItem.statuses[:active])

    assert_not draft_item.valid?

    draft_item.assign_attributes(
      title: 'Book of Random',
      type: types(:type_book),
      languages: [languages(:language_english)],
      creators: ['Jane Doe', 'Bob Smith'],
      subjects: ['Best Seller', 'Adventure'],
      date_created: Date.current,
      description: 'Really random description about this random book',
      member_of_paths: { community_id: [@community.id], collection_id: [@collection.id] }
    )

    assert_predicate draft_item, :valid?
  end

  test 'should run validations when on choose_license_and_visibility wizard step' do
    user = users(:user_regular)

    draft_item = DraftItem.new(
      user:,
      status: DraftItem.statuses[:active],
      wizard_step: DraftItem.wizard_steps[:choose_license_and_visibility],
      title: 'Book of Random',
      type: types(:type_book),
      languages: [languages(:language_english)],
      creators: ['Jane Doe', 'Bob Smith'],
      subjects: ['Best Seller', 'Adventure'],
      date_created: Date.current,
      description: 'Really random description about this random book',
      member_of_paths: { community_id: [@community.id], collection_id: [@collection.id] },
      # technically a draft_item is valid in this wizard step already, since license/visibility are given defaults
      # but this case let's force the validation to fail
      license: nil,
      visibility: nil
    )

    assert_not draft_item.valid?

    draft_item.assign_attributes(
      license: DraftItem.licenses[:attribution_non_commercial],
      visibility: DraftItem.visibilities[:open_access]
    )

    assert_predicate draft_item, :valid?
  end

  test 'should run validations when on file_uploads wizard step' do
    user = users(:user_regular)

    # Need to create an object for ActiveStorage because of global ID
    draft_item = draft_items(:draft_item_inactive)

    draft_item.update(
      user:,
      status: DraftItem.statuses[:active],
      wizard_step: DraftItem.wizard_steps[:upload_files],
      title: 'Book of Random',
      type: types(:type_book),
      languages: [languages(:language_english)],
      creators: ['Jane Doe', 'Bob Smith'],
      subjects: ['Best Seller', 'Adventure'],
      date_created: Date.current,
      description: 'Really random description about this random book',
      member_of_paths: { community_id: [@community.id], collection_id: [@collection.id] }
    )

    assert_not draft_item.valid?

    fake_file = ActiveStorage::Blob.create_and_upload!(
      io: StringIO.new('RandomData'),
      filename: 'book_cover.jpg',
      content_type: 'text/plain'
    )

    draft_item.files.attach fake_file

    assert_predicate draft_item, :valid?
  end

  test 'should handle license text validations' do
    user = users(:user_regular)

    draft_item = DraftItem.new(
      user:,
      status: DraftItem.statuses[:active],
      wizard_step: DraftItem.wizard_steps[:choose_license_and_visibility],
      title: 'Book of Random',
      type: types(:type_book),
      languages: [languages(:language_english)],
      creators: ['Jane Doe', 'Bob Smith'],
      subjects: ['Best Seller', 'Adventure'],
      date_created: Date.current,
      description: 'Really random description about this random book',
      member_of_paths: { community_id: [@community.id], collection_id: [@collection.id] },
      license: DraftItem.licenses[:license_text]
    )

    assert_not draft_item.valid?

    draft_item.assign_attributes(
      license_text_area: 'Random license text or url to a license goes here'
    )

    assert_predicate draft_item, :valid?
  end

  test 'should handle embargo end date visibility validations' do
    user = users(:user_regular)

    draft_item = DraftItem.new(
      user:,
      status: DraftItem.statuses[:active],
      wizard_step: DraftItem.wizard_steps[:choose_license_and_visibility],
      title: 'Book of Random',
      type: types(:type_book),
      languages: [languages(:language_english)],
      creators: ['Jane Doe', 'Bob Smith'],
      subjects: ['Best Seller', 'Adventure'],
      date_created: Date.current,
      description: 'Really random description about this random book',
      member_of_paths: { community_id: [@community.id], collection_id: [@collection.id] },
      visibility: DraftItem.visibilities[:embargo]
    )

    assert_not draft_item.valid?

    draft_item.assign_attributes(
      embargo_end_date: Date.current + 1.year
    )

    assert_predicate draft_item, :valid?
  end

  test 'should handle community/collection validations on member_of_paths' do
    user = users(:user_regular)

    draft_item = DraftItem.new(
      user:,
      status: DraftItem.statuses[:active],
      title: 'Book of Random',
      type: types(:type_book),
      languages: [languages(:language_english)],
      creators: ['Jane Doe', 'Bob Smith'],
      subjects: ['Best Seller', 'Adventure'],
      date_created: Date.current,
      description: 'Really random description about this random book',
      member_of_paths: { community_id: nil, collection_id: nil }
    )

    assert_not draft_item.valid?
    assert_equal 2, draft_item.errors.full_messages.count
    assert_equal "Community can't be blank", draft_item.errors.messages[:member_of_paths].first
    assert_equal "Collection can't be blank", draft_item.errors.messages[:member_of_paths].last

    draft_item.assign_attributes(
      member_of_paths: { community_id: ['random-uuid-123'], collection_id: ['random-uuid-abc'] }
    )

    assert_not draft_item.valid?
    assert_equal 2, draft_item.errors.full_messages.count
    assert_equal "Community can't be found", draft_item.errors.messages[:member_of_paths].first
    assert_equal "Collection can't be found", draft_item.errors.messages[:member_of_paths].last

    draft_item.assign_attributes(
      member_of_paths: { community_id: [@community.id], collection_id: [@collection.id] }
    )

    assert_predicate draft_item, :valid?

    @collection.read_only = true
    @collection.save!
    Collection.create!(title: 'Risque fantasy Books',
                       owner_id: user.id,
                       restricted: true,
                       community_id: @community.id)
    draft_item.assign_attributes(
      member_of_paths: { community_id: [@community.id], collection_id: [@collection.id] }
    )

    assert_not draft_item.valid?
    assert_equal ['Collection is frozen and not available for deposit'], draft_item.errors.messages[:member_of_paths]
    @collection.read_only = false
    @collection.save!

    # Regular user can't deposit to a restricted collection
    restricted_collection = Collection.create!(title: 'Risque fantasy Books',
                                               owner_id: user.id,
                                               restricted: true,
                                               community_id: @community.id)
    draft_item.assign_attributes(
      member_of_paths: { community_id: [@community.id], collection_id: [restricted_collection.id] }
    )

    assert_not draft_item.valid?
    assert_equal ['Deposit is restricted for this collection'], draft_item.errors.messages[:member_of_paths]

    # Admin user can deposit to a restricted collection
    user_admin = users(:user_admin)
    draft_item.user = user_admin

    assert_predicate draft_item, :valid?

    restricted_collection.destroy
  end

  # should be able to delete additional contributors https://github.com/ualbertalib/jupiter/issues/830
  test '#strip_input_fields should strip empty strings from array fields' do
    user = users(:user_regular)

    draft_item = DraftItem.new(
      user:,
      status: DraftItem.statuses[:active],
      title: 'Book of Random',
      type: types(:type_book),
      languages: [languages(:language_english)],
      creators: ['Jane Doe', 'Bob Smith'],
      subjects: ['Best Seller', 'Adventure'],
      date_created: Date.current,
      description: 'Really random description about this random book',
      member_of_paths: { community_id: [@community.id], collection_id: [@collection.id] },
      contributors: ['Carly Brown'],
      places: ['Edmonton'],
      time_periods: ['21st Century']
    )

    draft_item.assign_attributes(
      contributors: [''], places: [''], time_periods: ['']
    )

    assert_predicate draft_item, :valid?
    assert_nil draft_item.contributors
    assert_nil draft_item.places
    assert_nil draft_item.time_periods
  end

end
