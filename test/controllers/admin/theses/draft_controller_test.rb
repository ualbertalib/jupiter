require 'test_helper'

class Admin::Theses::DraftControllerTest < ActionDispatch::IntegrationTest

  def before_all
    super
    @community = locked_ldp_fixture(Community, :books).unlock_and_fetch_ldp_object(&:save!)
    @collection = Collection.new_locked_ldp_object(title: 'Thesis collection',
                                                   owner: 1,
                                                   restricted: true,
                                                   community_id: @community.id)
                            .unlock_and_fetch_ldp_object(&:save!)
  end

  setup do
    @admin = users(:admin)
  end

  test 'should be able to get to show page for a draft thesis' do
    sign_in_as @admin

    draft_thesis = draft_theses(:inactive)

    get admin_thesis_draft_url(id: draft_thesis.wizard_step, thesis_id: draft_thesis.id)
    assert_response :success
  end

  test 'should prevent prevent user from skipping ahead with uncompleted steps' do
    sign_in_as @admin

    draft_thesis = draft_theses(:inactive)

    # skip ahead right to upload files step
    get admin_thesis_draft_url(id: :upload_files, thesis_id: draft_thesis.id)

    # expect we get redirected back to describe thesis step with proper flash message
    assert_redirected_to admin_thesis_draft_path(id: :describe_thesis, thesis_id: draft_thesis)
    assert_equal I18n.t('admin.theses.draft.please_follow_the_steps'), flash[:alert]
  end

  test 'should prevent going to review_and_deposit_thesis if draft_thesis has no files attached' do
    sign_in_as @admin

    draft_thesis = draft_theses(:completed_choose_license_and_visibility_step)
    # Make draft_thesis to be in the review step (although it has no files and skipped the upload files step)
    draft_thesis.update(wizard_step: :review_and_deposit_thesis)

    # try to navigate to review and deposit thesis step now
    get admin_thesis_draft_url(id: :review_and_deposit_thesis, thesis_id: draft_thesis.id)

    # expect we get redirected back to upload files step with proper flash message
    assert_redirected_to admin_thesis_draft_path(id: :upload_files, thesis_id: draft_thesis)
    assert_equal I18n.t('admin.theses.draft.files_are_required_to_continue'), flash[:alert]
  end

  # wizard_step: :describe_thesis
  test 'should be able to update a draft thesis properly when saving describe_thesis form' do
    sign_in_as @admin

    draft_thesis = draft_theses(:inactive)

    patch admin_thesis_draft_url(id: :describe_thesis, thesis_id: draft_thesis.id), params: {
      draft_thesis: {
        title: 'Random Thesis',
        creator: 'Jane Doe',
        graduation_year: 2018,
        graduation_term: 'Spring',
        description: 'Really random description about this random thesis',
        community_id: [@community.id],
        collection_id: [@collection.id]
      }
    }

    assert_redirected_to admin_thesis_draft_path(id: :choose_license_and_visibility, thesis_id: draft_thesis.id)

    draft_thesis.reload
    assert_equal 'Random Thesis', draft_thesis.title
    assert_equal 'describe_thesis', draft_thesis.wizard_step
    assert_equal 'active', draft_thesis.status
  end

  # wizard_step: :choose_license_and_visibility
  test 'should be able to update a draft thesis properly when saving choose_license_and_visibility form' do
    sign_in_as @admin

    draft_thesis = draft_theses(:completed_describe_thesis_step)
    draft_thesis.member_of_paths = { 'community_id': [@community.id], 'collection_id': [@collection.id] }
    draft_thesis.save!

    patch admin_thesis_draft_url(id: :choose_license_and_visibility, thesis_id: draft_thesis.id), params: {
      draft_thesis: {
        rights: 'Open to everyone!',
        visibility: :embargo,
        embargo_end_date: Date.current + 1.year
      }
    }

    assert_redirected_to admin_thesis_draft_path(id: :upload_files, thesis_id: draft_thesis.id)

    draft_thesis.reload
    assert_equal 'Open to everyone!', draft_thesis.rights
    assert_equal 'embargo', draft_thesis.visibility
    assert_equal Date.current + 1.year, draft_thesis.embargo_end_date
    assert_equal 'choose_license_and_visibility', draft_thesis.wizard_step
    assert_equal 'active', draft_thesis.status
  end

  # wizard_step: :upload_files
  test 'should be able to update a draft thesis properly when saving upload_files form that has file attachments' do
    sign_in_as @admin

    draft_thesis = draft_theses(:completed_choose_license_and_visibility_step)
    draft_thesis.member_of_paths = { 'community_id': [@community.id], 'collection_id': [@collection.id] }
    draft_thesis.save!

    file_fixture = fixture_file_upload('/files/image-sample.jpeg', 'image/jpeg')
    image_file = ActiveStorage::Blob.create_after_upload!(
      io: file_fixture.open,
      filename: file_fixture.original_filename, content_type: file_fixture.content_type
    )

    draft_thesis.files.attach image_file

    # Here upload_files all it does is check if files been uploaded (via ajax and files_controller)
    # and if so, updated the wizard_step to upload_files and redirects to review_and_deposit_thesis
    patch admin_thesis_draft_url(id: :upload_files, thesis_id: draft_thesis.id)

    assert_redirected_to admin_thesis_draft_path(id: :review_and_deposit_thesis, thesis_id: draft_thesis.id)

    draft_thesis.reload

    assert_equal 'upload_files', draft_thesis.wizard_step
    assert_equal 'active', draft_thesis.status
  end

  test 'should not be able to update a draft thesis when saving upload_files form that has no file attachments' do
    sign_in_as @admin

    draft_thesis = draft_theses(:completed_choose_license_and_visibility_step)

    # Here upload_files all it does is check if files been uploaded (via ajax and files_controller)
    # and if so, updated the wizard_step to upload_files and redirects to review_and_deposit_thesis
    patch admin_thesis_draft_url(id: :upload_files, thesis_id: draft_thesis.id)

    assert_response :success # silly but this is actually rerendering upload_files with errors
    assert_match 'Files can&#39;t be blank', @response.body
    draft_thesis.reload

    assert_equal 'choose_license_and_visibility', draft_thesis.wizard_step
    assert_equal 'active', draft_thesis.status
  end

  # wizard_step: :review_and_deposit_thesis
  test 'should be able to review and deposit a draft thesis properly when saving review_and_deposit_thesis form' do
    sign_in_as @admin

    draft_thesis = draft_theses(:completed_choose_license_and_visibility_step)
    draft_thesis.member_of_paths = { 'community_id': [@community.id], 'collection_id': [@collection.id] }

    file_fixture = fixture_file_upload('/files/image-sample.jpeg', 'image/jpeg')
    image_file = ActiveStorage::Blob.create_after_upload!(
      io: file_fixture.open,
      filename: file_fixture.original_filename, content_type: file_fixture.content_type
    )

    draft_thesis.files.attach image_file

    draft_thesis.update(wizard_step: :upload_files)

    assert_difference('Thesis.count', 1) do
      patch admin_thesis_draft_url(id: :review_and_deposit_thesis, thesis_id: draft_thesis.id)
    end

    assert_redirected_to item_url(Thesis.last)
    assert_equal I18n.t('admin.theses.draft.successful_deposit'), flash[:notice]

    draft_thesis.reload

    assert_equal 'review_and_deposit_thesis', draft_thesis.wizard_step
    assert_equal 'archived', draft_thesis.status
  end

  test 'should be able to update an old step without changing the current wizard_step of the draft thesis' do
    sign_in_as @admin

    draft_thesis = draft_theses(:completed_choose_license_and_visibility_step)
    draft_thesis.member_of_paths = { 'community_id': [@community.id], 'collection_id': [@collection.id] }

    file_fixture = fixture_file_upload('/files/image-sample.jpeg', 'image/jpeg')
    image_file = ActiveStorage::Blob.create_after_upload!(
      io: file_fixture.open,
      filename: file_fixture.original_filename, content_type: file_fixture.content_type
    )

    draft_thesis.files.attach image_file

    draft_thesis.update(wizard_step: :upload_files)

    patch admin_thesis_draft_url(id: :choose_license_and_visibility, thesis_id: draft_thesis.id), params: {
      draft_thesis: {
        rights: 'Open to all!'
      }
    }

    assert_redirected_to admin_thesis_draft_path(id: :upload_files, thesis_id: draft_thesis.id)

    draft_thesis.reload

    # wizard step should still :upload_files (unchanged) instead of being updated to :choose_license_and_visibility
    assert_equal 'upload_files', draft_thesis.wizard_step
    assert_equal 'active', draft_thesis.status
  end

  test 'should not be able to create a draft thesis if not logged in' do
    assert_no_difference('DraftThesis.count') do
      assert_raises ActionController::RoutingError do
        post create_draft_admin_theses_url
      end
    end
  end

  test 'should not be able to create a draft thesis if not admin' do
    sign_in_as users(:regular)

    assert_no_difference('DraftThesis.count') do
      assert_raises ActionController::RoutingError do
        post create_draft_admin_theses_url
      end
    end
  end

  test 'should be able to create a draft thesis if logged in' do
    sign_in_as @admin

    assert_difference('DraftThesis.count', 1) do
      post create_draft_admin_theses_url
    end

    assert_redirected_to admin_thesis_draft_path(id: :describe_thesis, thesis_id: DraftThesis.last.id)
  end

  test 'other admins should be able to delete a draft thesis even if they do not own the thesis' do
    sign_in_as users(:admin_two)

    draft_thesis = draft_theses(:completed_choose_license_and_visibility_step)

    assert_difference('DraftThesis.count', -1) do
      delete admin_thesis_delete_draft_url(thesis_id: draft_thesis.id)
    end

    assert_redirected_to root_url
  end

  test 'should be able to delete a draft thesis if logged in and you own the thesis' do
    sign_in_as @admin

    draft_thesis = draft_theses(:completed_choose_license_and_visibility_step)

    assert_difference('DraftThesis.count', -1) do
      delete admin_thesis_delete_draft_url(thesis_id: draft_thesis.id)
    end

    assert_redirected_to root_url
  end

end
