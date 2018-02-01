require 'test_helper'

class DraftItemTest < ActiveSupport::TestCase

  context 'enums' do
    should define_enum_for(:status)
    should define_enum_for(:wizard_step)
    should define_enum_for(:license)
    should define_enum_for(:visibility)
    should define_enum_for(:visibility_after_embargo)
  end

  context 'associations' do
    should have_many(:draft_items_languages).dependent(:destroy)
    should have_many(:languages).through(:draft_items_languages)
    should belong_to(:type)
    should belong_to(:user)
  end

  context 'validations' do
    should 'not be able to create a draft item without user' do
      draft_item = DraftItem.new
      refute draft_item.valid?
      assert_equal 'User must exist', draft_item.errors.full_messages.first
    end

    should 'be able to create a draft item with user when on inactive status' do
      user = users(:regular)
      draft_item = DraftItem.new(user: user)
      assert draft_item.valid?
    end

    should 'run validations when on describe_item step' do
      user = users(:regular)
      draft_item = DraftItem.new(user: user, status: DraftItem.statuses[:active])
      refute draft_item.valid?

      draft_item.assign_attributes(
        title: 'Book of Random',
        type: types(:book),
        languages: [languages(:english)],
        creators: ['Jane Doe', 'Bob Smith'],
        subjects: ['Best Seller', 'Adventure'],
        date_created: Date.current,
        description: 'Really random description about this random book',
        member_of_paths: { community_id: ['random-uuid-123'], collection_id: ['random-uuid-abc'] }
      )
      assert draft_item.valid?
    end

    should 'run validations when on choose_license_and_visibility wizard step' do
      user = users(:regular)

      draft_item = DraftItem.new(
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
        member_of_paths: { community_id: ['random-uuid-123'], collection_id: ['random-uuid-abc'] },
        # technically a draft_item is valid in this wizard step already, since license/visibility are given defaults
        # but this case let's force the validation to fail
        license: nil,
        visibility: nil
      )

      refute draft_item.valid?

      draft_item.assign_attributes(
        license: DraftItem.licenses[:attribution_non_commercial],
        visibility: DraftItem.visibilities[:open_access]
      )

      assert draft_item.valid?
    end

    should 'run validations when on file_uploads wizard step' do
      user = users(:regular)

      # Need to create an object for ActiveStorage because of global ID
      draft_item = draft_items(:inactive)

      draft_item.update_attributes(
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
        member_of_paths: { community_id: ['random-uuid-123'], collection_id: ['random-uuid-abc'] }
      )
      refute draft_item.valid?

      fake_file = ActiveStorage::Blob.create_after_upload!(
        io: StringIO.new('RandomData'),
        filename: 'book_cover.jpg',
        content_type: 'text/plain'
      )

      draft_item.files.attach fake_file

      assert draft_item.valid?
    end

    should 'handle license text validations' do
      user = users(:regular)

      draft_item = DraftItem.new(
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
        member_of_paths: { community_id: ['random-uuid-123'], collection_id: ['random-uuid-abc'] },
        license: DraftItem.licenses[:license_text]
      )

      refute draft_item.valid?

      draft_item.assign_attributes(
        license_text_area: 'Random license text or url to a license goes here'
      )

      assert draft_item.valid?
    end

    should 'handle embargo end date visibility validations' do
      user = users(:regular)

      draft_item = DraftItem.new(
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
        member_of_paths: { community_id: ['random-uuid-123'], collection_id: ['random-uuid-abc'] },
        visibility: DraftItem.visibilities[:embargo]
      )

      refute draft_item.valid?

      draft_item.assign_attributes(
        embargo_end_date: Date.current + 1.year
      )

      assert draft_item.valid?
    end

    should 'handle community/collection validations on member_of_paths' do
      user = users(:regular)

      draft_item = DraftItem.new(
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

      refute draft_item.valid?
      assert_equal 2, draft_item.errors.full_messages.count
      assert_equal "Community can't be blank", draft_item.errors.messages[:member_of_paths].first
      assert_equal "Collection can't be blank", draft_item.errors.messages[:member_of_paths].last

      draft_item.assign_attributes(
        member_of_paths: { community_id: ['random-uuid-123'], collection_id: ['random-uuid-abc'] }
      )
      assert draft_item.valid?
    end
  end

end
