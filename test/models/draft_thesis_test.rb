require 'test_helper'

class DraftThesisTest < ActiveSupport::TestCase

  def before_all
    super
    @community = locked_ldp_fixture(Community, :books).unlock_and_fetch_ldp_object(&:save!)
    @collection = Collection.new_locked_ldp_object(title: 'Risque fantasy Books',
                                                   owner: 1,
                                                   restricted: true,
                                                   community_id: @community.id)
                            .unlock_and_fetch_ldp_object(&:save!)
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
    user = users(:admin)
    draft_thesis = DraftThesis.new(user: user)
    assert draft_thesis.valid?
  end

  test 'should run validations when on describe_item step' do
    user = users(:admin)
    draft_thesis = DraftThesis.new(user: user, status: DraftThesis.statuses[:active])
    assert_not draft_thesis.valid?

    draft_thesis.assign_attributes(
      title: 'Thesis of Random',
      creator: 'Jane Doe',
      description: 'Really random description about this random thesis',
      graduation_term: 'Spring',
      graduation_year: 2018,
      member_of_paths: { community_id: [@community.id], collection_id: [@collection.id] }
    )

    assert draft_thesis.valid?
  end

  test 'should run validations when on choose_license_and_visibility wizard step' do
    user = users(:admin)

    draft_thesis = DraftThesis.new(
      user: user,
      status: DraftThesis.statuses[:active],
      wizard_step: DraftThesis.wizard_steps[:choose_license_and_visibility],
      title: 'Thesis of Random',
      creator: 'Jane Doe',
      description: 'Really random description about this random thesis',
      graduation_term: 'Spring',
      graduation_year: 2018,
      member_of_paths: { community_id: [@community.id], collection_id: [@collection.id] },
      visibility: nil,
      rights: nil
    )

    assert_not draft_thesis.valid?

    draft_thesis.assign_attributes(
      visibility: DraftThesis.visibilities[:open_access],
      rights: 'License text goes here'
    )

    assert draft_thesis.valid?
  end

  test 'should run validations when on file_uploads wizard step' do
    user = users(:admin)

    # Need to create an object for ActiveStorage because of global ID
    draft_thesis = draft_theses(:inactive)

    draft_thesis.update(
      user: user,
      status: DraftThesis.statuses[:active],
      wizard_step: DraftThesis.wizard_steps[:upload_files],
      title: 'Thesis of Random',
      creator: 'Jane Doe',
      description: 'Really random description about this random thesis',
      graduation_term: 'Spring',
      graduation_year: 2018,
      visibility: DraftThesis.visibilities[:open_access],
      rights: 'License text goes here',
      member_of_paths: { community_id: [@community.id], collection_id: [@collection.id] }
    )
    assert_not draft_thesis.valid?

    fake_file = ActiveStorage::Blob.create_after_upload!(
      io: StringIO.new('RandomData'),
      filename: 'book_cover.jpg',
      content_type: 'text/plain'
    )

    draft_thesis.files.attach fake_file

    assert draft_thesis.valid?
  end

  test 'should handle embargo end date visibility validations' do
    user = users(:admin)

    draft_thesis = DraftThesis.new(
      user: user,
      status: DraftThesis.statuses[:active],
      wizard_step: DraftThesis.wizard_steps[:choose_license_and_visibility],
      title: 'Thesis of Random',
      creator: 'Jane Doe',
      description: 'Really random description about this random thesis',
      graduation_term: 'Spring',
      graduation_year: 2018,
      member_of_paths: { community_id: [@community.id], collection_id: [@collection.id] },
      visibility: DraftThesis.visibilities[:embargo],
      rights: 'License text goes here'
    )

    assert_not draft_thesis.valid?

    draft_thesis.assign_attributes(
      embargo_end_date: Date.current + 1.year
    )

    assert draft_thesis.valid?
  end

  test 'should handle community/collection validations on member_of_paths' do
    user = users(:admin)

    draft_thesis = DraftThesis.new(
      user: user,
      status: DraftThesis.statuses[:active],
      title: 'Thesis of Random',
      creator: 'Jane Doe',
      description: 'Really random description about this random thesis',
      graduation_term: 'Spring',
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
    assert draft_thesis.valid?
  end

  test 'regular user cannot deposit' do
    user = users(:regular)

    draft_thesis = DraftThesis.new(
      user: user,
      status: DraftThesis.statuses[:active],
      title: 'Thesis of Random',
      creator: 'Jane Doe',
      description: 'Really random description about this random thesis',
      graduation_term: 'Spring',
      graduation_year: 2018,
      member_of_paths: { community_id: [@community.id], collection_id: [@collection.id] }
    )

    assert_not draft_thesis.valid?
    assert_equal ['Deposit is restricted for this collection'], draft_thesis.errors.messages[:member_of_paths]
  end

  test 'cannot deposit thesis into a non restricted collection' do
    user = users(:admin)
    non_restricted_collection = Collection.new_locked_ldp_object(title: 'Risque fantasy Books',
                                                                 owner: 1,
                                                                 community_id: @community.id)
                                          .unlock_and_fetch_ldp_object(&:save!)

    draft_thesis = DraftThesis.new(
      user: user,
      status: DraftThesis.statuses[:active],
      title: 'Thesis of Random',
      creator: 'Jane Doe',
      description: 'Really random description about this random thesis',
      graduation_term: 'Spring',
      graduation_year: 2018,
      member_of_paths: { community_id: [@community.id], collection_id: [non_restricted_collection.id] }
    )

    assert_not draft_thesis.valid?
    assert_equal ['Deposit is restricted for this collection'], draft_thesis.errors.messages[:member_of_paths]
  end

end
