require 'test_helper'

class DraftItemTest < ActiveSupport::TestCase

  def before_all
    super
    @community = locked_ldp_fixture(Community, :books).unlock_and_fetch_ldp_object(&:save!)
    @collection = locked_ldp_fixture(Collection, :books).unlock_and_fetch_ldp_object(&:save!)
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
    draft_item = DraftItem.drafts.new
    assert_not draft_item.valid?
    assert_equal 'User must exist', draft_item.errors.full_messages.first
  end

  test 'should be able to create a draft item with user when on inactive status' do
    user = users(:regular)
    draft_item = DraftItem.drafts.new(user: user)
    assert draft_item.valid?
  end

  test 'should run validations when on describe_item step' do
    user = users(:regular)
    draft_item = DraftItem.drafts.new(user: user, status: DraftItem.statuses[:active])
    assert_not draft_item.valid?

    draft_item.assign_attributes(
      title: 'Book of Random',
      type: types(:book),
      languages: [languages(:english)],
      creators: ['Jane Doe', 'Bob Smith'],
      subjects: ['Best Seller', 'Adventure'],
      date_created: Date.current,
      description: 'Really random description about this random book',
      member_of_paths: { community_id: [@community.id], collection_id: [@collection.id] }
    )
    assert draft_item.valid?
  end

  test 'should run validations when on choose_license_and_visibility wizard step' do
    user = users(:regular)

    draft_item = DraftItem.drafts.new(
      user: user,
      status: DraftItem.statuses[:active],
      wizard_step: DraftItem.wizard_steps[:choose_license_and_visibility],
      title: 'Book of Random',
      type: types(:book),
      languages: [languages(:english)],
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

    assert draft_item.valid?
  end

  test 'should run validations when on file_uploads wizard step' do
    user = users(:regular)

    # Need to create an object for ActiveStorage because of global ID
    draft_item = draft_items(:inactive)

    draft_item.update(
      user: user,
      status: DraftItem.statuses[:active],
      wizard_step: DraftItem.wizard_steps[:upload_files],
      title: 'Book of Random',
      type: types(:book),
      languages: [languages(:english)],
      creators: ['Jane Doe', 'Bob Smith'],
      subjects: ['Best Seller', 'Adventure'],
      date_created: Date.current,
      description: 'Really random description about this random book',
      member_of_paths: { community_id: [@community.id], collection_id: [@collection.id] }
    )
    assert_not draft_item.valid?

    fake_file = ActiveStorage::Blob.create_after_upload!(
      io: StringIO.new('RandomData'),
      filename: 'book_cover.jpg',
      content_type: 'text/plain'
    )

    draft_item.files.attach fake_file

    assert draft_item.valid?
  end

  test 'should handle license text validations' do
    user = users(:regular)

    draft_item = DraftItem.drafts.new(
      user: user,
      status: DraftItem.statuses[:active],
      wizard_step: DraftItem.wizard_steps[:choose_license_and_visibility],
      title: 'Book of Random',
      type: types(:book),
      languages: [languages(:english)],
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
    assert draft_item.valid?
  end

  test 'should handle embargo end date visibility validations' do
    user = users(:regular)

    draft_item = DraftItem.drafts.new(
      user: user,
      status: DraftItem.statuses[:active],
      wizard_step: DraftItem.wizard_steps[:choose_license_and_visibility],
      title: 'Book of Random',
      type: types(:book),
      languages: [languages(:english)],
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

    assert draft_item.valid?
  end

  test 'should handle community/collection validations on member_of_paths' do
    user = users(:regular)

    draft_item = DraftItem.drafts.new(
      user: user,
      status: DraftItem.statuses[:active],
      title: 'Book of Random',
      type: types(:book),
      languages: [languages(:english)],
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
    assert draft_item.valid?

    # Regular user can't deposit to a restricted collection
    restricted_collection = Collection.new(title: 'Risque fantasy Books',
                                                             owner_id: 1,
                                                             restricted: true,
                                                             community_id: @community.id)
                                      .unlock_and_fetch_ldp_object(&:save!)
    draft_item.assign_attributes(
      member_of_paths: { community_id: [@community.id], collection_id: [restricted_collection.id] }
    )
    assert_not draft_item.valid?
    assert_equal ['Deposit is restricted for this collection'], draft_item.errors.messages[:member_of_paths]

    # Admin user can deposit to a restricted collection
    admin = users(:admin)
    draft_item.user = admin
    assert draft_item.valid?
  end

  # should be able to delete additional contributors https://github.com/ualbertalib/jupiter/issues/830
  test '#strip_input_fields should strip empty strings from array fields' do
    user = users(:regular)

    draft_item = DraftItem.drafts.new(
      user: user,
      status: DraftItem.statuses[:active],
      title: 'Book of Random',
      type: types(:book),
      languages: [languages(:english)],
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

    assert draft_item.valid?
    assert_nil draft_item.contributors
    assert_nil draft_item.places
    assert_nil draft_item.time_periods
  end

end
