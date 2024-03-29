require 'test_helper'

class DraftThesisTest < ActiveSupport::TestCase

  setup do
    @community = communities(:community_thesis)
    @collection = collections(:collection_thesis)
  end

  test 'enums' do
    assert define_enum_for(:status)
    assert define_enum_for(:wizard_step)
    assert define_enum_for(:visibility)
    assert define_enum_for(:visibility_after_embargo)
  end

  test 'associations' do
    assert belong_to(:language)
    assert belong_to(:user)
  end

  test 'should not be able to create a draft thesis without user' do
    draft_thesis = DraftThesis.new

    assert_not draft_thesis.valid?
    assert_equal 'User must exist', draft_thesis.errors.full_messages.first
  end

  test 'should be able to create a draft thesis with user when on inactive status' do
    user = users(:user_admin)
    draft_thesis = DraftThesis.new(user:)

    assert_predicate draft_thesis, :valid?
  end

  test 'should run validations when on describe_item step' do
    user = users(:user_admin)
    draft_thesis = DraftThesis.new(user:, status: DraftThesis.statuses[:active])

    assert_not draft_thesis.valid?
    assert_equal 5, draft_thesis.errors.full_messages.count

    draft_thesis.assign_attributes(
      title: 'Thesis of Random',
      creator: 'Jane Doe',
      description: 'Really random description about this random thesis',
      graduation_term: '06',
      graduation_year: 2018,
      member_of_paths: { community_id: [@community.id], collection_id: [@collection.id] }
    )

    assert_predicate draft_thesis, :valid?
  end

  test 'should run validations when on choose_license_and_visibility wizard step' do
    user = users(:user_admin)

    draft_thesis = DraftThesis.new(
      user:,
      status: DraftThesis.statuses[:active],
      wizard_step: DraftThesis.wizard_steps[:choose_license_and_visibility],
      title: 'Thesis of Random',
      creator: 'Jane Doe',
      description: 'Really random description about this random thesis',
      graduation_term: '06',
      graduation_year: 2018,
      member_of_paths: { community_id: [@community.id], collection_id: [@collection.id] },
      visibility: nil,
      rights: nil
    )

    assert_not draft_thesis.valid?
    assert_equal 2, draft_thesis.errors.full_messages.count

    draft_thesis.assign_attributes(
      visibility: DraftThesis.visibilities[:open_access],
      rights: 'License text goes here'
    )

    assert_predicate draft_thesis, :valid?
  end

  test 'should run validations when on file_uploads wizard step' do
    user = users(:user_admin)

    # Need to create an object for ActiveStorage because of global ID
    draft_thesis = draft_theses(:draft_thesis_inactive)

    draft_thesis.update(
      user:,
      status: DraftThesis.statuses[:active],
      wizard_step: DraftThesis.wizard_steps[:upload_files],
      title: 'Thesis of Random',
      creator: 'Jane Doe',
      description: 'Really random description about this random thesis',
      graduation_term: '06',
      graduation_year: 2018,
      visibility: DraftThesis.visibilities[:open_access],
      rights: 'License text goes here',
      member_of_paths: { community_id: [@community.id], collection_id: [@collection.id] }
    )

    assert_not draft_thesis.valid?
    assert_equal "Files can't be blank", draft_thesis.errors.full_messages.first

    fake_file = ActiveStorage::Blob.create_and_upload!(
      io: StringIO.new('RandomData'),
      filename: 'book_cover.jpg',
      content_type: 'text/plain'
    )

    draft_thesis.files.attach fake_file

    assert_predicate draft_thesis, :valid?
  end

  test 'should handle embargo end date visibility validations' do
    user = users(:user_admin)

    draft_thesis = DraftThesis.new(
      user:,
      status: DraftThesis.statuses[:active],
      wizard_step: DraftThesis.wizard_steps[:choose_license_and_visibility],
      title: 'Thesis of Random',
      creator: 'Jane Doe',
      description: 'Really random description about this random thesis',
      graduation_term: '06',
      graduation_year: 2018,
      member_of_paths: { community_id: [@community.id], collection_id: [@collection.id] },
      visibility: DraftThesis.visibilities[:embargo],
      rights: 'License text goes here'
    )

    assert_not draft_thesis.valid?
    assert_equal "Embargo end date can't be blank", draft_thesis.errors.full_messages.first

    draft_thesis.assign_attributes(
      embargo_end_date: Date.current + 1.year
    )

    assert_predicate draft_thesis, :valid?
  end

  test 'should handle community/collection validations on member_of_paths' do
    user = users(:user_admin)

    draft_thesis = DraftThesis.new(
      user:,
      status: DraftThesis.statuses[:active],
      title: 'Thesis of Random',
      creator: 'Jane Doe',
      description: 'Really random description about this random thesis',
      graduation_term: '06',
      graduation_year: 2018,
      member_of_paths: { community_id: nil, collection_id: nil }
    )

    assert_not draft_thesis.valid?
    assert_equal 2, draft_thesis.errors.full_messages.count
    assert_equal "Community can't be blank", draft_thesis.errors.messages[:member_of_paths].first
    assert_equal "Collection can't be blank", draft_thesis.errors.messages[:member_of_paths].last

    draft_thesis.assign_attributes(
      member_of_paths: { community_id: ['random-uuid-123'], collection_id: ['random-uuid-abc'] }
    )

    assert_not draft_thesis.valid?
    assert_equal 2, draft_thesis.errors.full_messages.count
    assert_equal "Community can't be found", draft_thesis.errors.messages[:member_of_paths].first
    assert_equal "Collection can't be found", draft_thesis.errors.messages[:member_of_paths].last

    draft_thesis.assign_attributes(
      member_of_paths: { community_id: [@community.id], collection_id: [@collection.id] }
    )

    assert_predicate draft_thesis, :valid?
  end

  test 'regular user cannot deposit' do
    user = users(:user_regular)

    draft_thesis = DraftThesis.new(
      user:,
      status: DraftThesis.statuses[:active],
      title: 'Thesis of Random',
      creator: 'Jane Doe',
      description: 'Really random description about this random thesis',
      graduation_term: '06',
      graduation_year: 2018,
      member_of_paths: { community_id: [@community.id], collection_id: [@collection.id] }
    )

    assert_not draft_thesis.valid?
    assert_equal ['Deposit is restricted for this collection'], draft_thesis.errors.messages[:member_of_paths]
  end

  test 'cannot deposit thesis into a non restricted collection' do
    user = users(:user_admin)
    non_restricted_collection = Collection.create!(title: 'Risque fantasy Books',
                                                   owner_id: users(:user_admin).id,
                                                   community_id: @community.id)

    draft_thesis = DraftThesis.new(
      user:,
      status: DraftThesis.statuses[:active],
      title: 'Thesis of Random',
      creator: 'Jane Doe',
      description: 'Really random description about this random thesis',
      graduation_term: '06',
      graduation_year: 2018,
      member_of_paths: { community_id: [@community.id], collection_id: [non_restricted_collection.id] }
    )

    assert_not draft_thesis.valid?
    assert_equal ['Deposit is restricted for this collection'], draft_thesis.errors.messages[:member_of_paths]

    non_restricted_collection.destroy
  end

  test 'parse_graduation_term_from_fedora works correctly' do
    user = users(:user_admin)
    draft_thesis = DraftThesis.new(user:)

    assert_equal '11', draft_thesis.send(:parse_graduation_term_from_fedora, '2018-11')
    assert_equal '06', draft_thesis.send(:parse_graduation_term_from_fedora, '2018-06')
    assert_nil draft_thesis.send(:parse_graduation_term_from_fedora, '2018-03')
    assert_nil draft_thesis.send(:parse_graduation_term_from_fedora, '2018')
    assert_nil draft_thesis.send(:parse_graduation_term_from_fedora, nil)
  end

  test 'should handle thesis description validations' do
    user = users(:user_admin)

    draft_thesis = DraftThesis.new(
      user:,
      status: DraftThesis.statuses[:active],
      wizard_step: DraftThesis.wizard_steps[:choose_license_and_visibility],
      title: 'Thesis Missing Description',
      creator: 'Jane Doe',
      description: '',
      graduation_term: '06',
      graduation_year: 2018,
      member_of_paths: { community_id: [@community.id], collection_id: [@collection.id] },
      visibility: DraftThesis.visibilities[:embargo],
      embargo_end_date: Date.current + 1.year,
      rights: 'License text goes here'
    )

    assert_not draft_thesis.valid?
    assert_equal "Description can't be blank", draft_thesis.errors.full_messages.first

    draft_thesis.assign_attributes(
      graduation_year: 2000
    )

    assert_predicate draft_thesis, :valid?
  end

end
