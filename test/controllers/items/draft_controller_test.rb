require 'test_helper'

class Items::DraftControllerTest < ActionDispatch::IntegrationTest

  setup do
    @community = communities(:community_books)
    @collection = collections(:collection_fantasy)
    @user = users(:user_regular)
  end

  test 'should be able to get to show page for a draft item' do
    sign_in_as @user

    draft_item = draft_items(:draft_item_inactive)

    get item_draft_url(id: draft_item.wizard_step, item_id: draft_item.id)

    assert_response :success
  end

  test 'should prevent user from skipping ahead with uncompleted steps' do
    sign_in_as @user

    draft_item = draft_items(:draft_item_inactive)

    # skip ahead right to upload files step
    get item_draft_url(id: :upload_files, item_id: draft_item.id)

    # expect we get redirected back to describe item step with proper flash message
    assert_redirected_to item_draft_path(id: :describe_item, item_id: draft_item)
    assert_equal I18n.t('items.draft.please_follow_the_steps'), flash[:alert]
  end

  test 'should prevent going to review_and_deposit_item if draft_item has no files attached' do
    sign_in_as @user

    draft_item = draft_items(:draft_item_completed_choose_license_and_visibility_step)
    # Make draft_item to be in the review step (although it has no files and skipped the upload files step)
    draft_item.update(wizard_step: :review_and_deposit_item)

    # try to navigate to review and deposit item step now
    get item_draft_url(id: :review_and_deposit_item, item_id: draft_item.id)

    # expect we get redirected back to upload files step with proper flash message
    assert_redirected_to item_draft_path(id: :upload_files, item_id: draft_item)
    assert_equal I18n.t('items.draft.files_are_required_to_continue'), flash[:alert]
  end

  # wizard_step: :describe_item
  test 'should be able to update a draft item properly when saving describe_item form' do
    sign_in_as @user
    draft_item = draft_items(:draft_item_inactive)

    patch item_draft_url(id: :describe_item, item_id: draft_item.id), params: {
      draft_item: {
        title: 'Random Book',
        type_id: types(:type_book).id,
        language_ids: [languages(:language_english).id],
        creators: ['Jane Doe', 'Bob Smith'],
        subjects: ['Best Seller', 'Adventure'],
        date_created: Date.current,
        description: 'Really random description about this random book',
        community_id: [@community.id],
        collection_id: [@collection.id]
      }
    }

    assert_redirected_to item_draft_path(id: :choose_license_and_visibility, item_id: draft_item.id)
    get profile_url

    assert_response :success
    assert_includes @response.body, 'Random Book'
    draft_item.reload

    assert_equal 'Random Book', draft_item.title
    assert_equal 'describe_item', draft_item.wizard_step
    assert_equal 'active', draft_item.status
  end

  # wizard_step: :choose_license_and_visibility
  test 'should be able to update a draft item properly when saving choose_license_and_visibility form' do
    sign_in_as @user

    draft_item = draft_items(:draft_item_completed_describe_item_step)
    draft_item.member_of_paths = { community_id: [@community.id], collection_id: [@collection.id] }
    draft_item.save!

    patch item_draft_url(id: :choose_license_and_visibility, item_id: draft_item.id), params: {
      draft_item: {
        license: :public_domain_mark,
        visibility: :embargo,
        embargo_end_date: Date.current + 1.year
      }
    }

    assert_redirected_to item_draft_path(id: :upload_files, item_id: draft_item.id)

    draft_item.reload

    assert_equal 'public_domain_mark', draft_item.license
    assert_equal 'embargo', draft_item.visibility
    assert_equal (Date.current + 1.year).to_datetime, draft_item.embargo_end_date
    assert_equal 'choose_license_and_visibility', draft_item.wizard_step
    assert_equal 'active', draft_item.status
  end

  # wizard_step: :upload_files
  test 'should be able to update a draft item properly when saving upload_files form that has file attachments' do
    sign_in_as @user

    draft_item = draft_items(:draft_item_completed_choose_license_and_visibility_step)
    draft_item.member_of_paths = { community_id: [@community.id], collection_id: [@collection.id] }
    draft_item.save!

    file_fixture = fixture_file_upload('/image-sample.jpeg', 'image/jpeg')
    image_file = ActiveStorage::Blob.create_and_upload!(
      io: file_fixture.open,
      filename: file_fixture.original_filename, content_type: file_fixture.content_type
    )

    draft_item.files.attach image_file

    # Here upload_files all it does is check if files been uploaded (via ajax and files_controller)
    # and if so, updated the wizard_step to upload_files and redirects to review_and_deposit_item
    patch item_draft_url(id: :upload_files, item_id: draft_item.id)

    assert_redirected_to item_draft_path(id: :review_and_deposit_item, item_id: draft_item.id)

    draft_item.reload

    assert_equal 'upload_files', draft_item.wizard_step
    assert_equal 'active', draft_item.status
  end

  test 'should not be able to update a draft item when saving upload_files form that has no file attachments' do
    sign_in_as @user

    draft_item = draft_items(:draft_item_completed_choose_license_and_visibility_step)

    # Here upload_files all it does is check if files been uploaded (via ajax and files_controller)
    # and if so, updated the wizard_step to upload_files and redirects to review_and_deposit_item
    patch item_draft_url(id: :upload_files, item_id: draft_item.id)

    assert_response :unprocessable_entity
    assert_match 'Files can&#39;t be blank', @response.body
    draft_item.reload

    assert_equal 'choose_license_and_visibility', draft_item.wizard_step
    assert_equal 'active', draft_item.status
  end

  # wizard_step: :review_and_deposit_item
  test 'should be able to review and deposit a draft item properly when saving review_and_deposit_item form' do
    sign_in_as @user

    draft_item = draft_items(:draft_item_completed_choose_license_and_visibility_step)
    draft_item.member_of_paths = { community_id: [@community.id], collection_id: [@collection.id] }

    file_fixture = fixture_file_upload('/image-sample.jpeg', 'image/jpeg')
    image_file = ActiveStorage::Blob.create_and_upload!(
      io: file_fixture.open,
      filename: file_fixture.original_filename, content_type: file_fixture.content_type
    )

    draft_item.files.attach image_file

    draft_item.update(wizard_step: :upload_files)

    assert_difference('Item.count', 1) do
      patch item_draft_url(id: :review_and_deposit_item, item_id: draft_item.id)
    end

    draft_item.reload

    assert_predicate draft_item.uuid, :present?

    item = Item.find(draft_item.uuid)

    assert_predicate item, :present?

    assert_redirected_to item_url(item)
    assert_equal I18n.t('items.draft.successful_deposit'), flash[:notice]

    assert_equal 'review_and_deposit_item', draft_item.wizard_step
    assert_equal 'archived', draft_item.status
  end

  test 'should be able to update an old step without changing the current wizard_step of the draft item' do
    sign_in_as @user

    draft_item = draft_items(:draft_item_completed_choose_license_and_visibility_step)
    draft_item.member_of_paths = { community_id: [@community.id], collection_id: [@collection.id] }

    file_fixture = fixture_file_upload('/image-sample.jpeg', 'image/jpeg')
    image_file = ActiveStorage::Blob.create_and_upload!(
      io: file_fixture.open,
      filename: file_fixture.original_filename, content_type: file_fixture.content_type
    )

    draft_item.files.attach image_file

    draft_item.update(wizard_step: :upload_files)

    patch item_draft_url(id: :choose_license_and_visibility, item_id: draft_item.id), params: {
      draft_item: {
        license: :public_domain_mark
      }
    }

    assert_redirected_to item_draft_path(id: :upload_files, item_id: draft_item.id)

    draft_item.reload

    # wizard step should still :upload_files (unchanged) instead of being updated to :choose_license_and_visibility
    assert_equal 'upload_files', draft_item.wizard_step
    assert_equal 'active', draft_item.status
  end

  test 'should not be able to create a draft item if not logged in' do
    assert_no_difference('DraftItem.count') do
      post create_draft_items_url
    end
    assert_redirected_to root_url
  end

  test 'should be able to create a draft item if logged in' do
    sign_in_as @user

    assert_difference('DraftItem.count', 1) do
      post create_draft_items_url
    end
    assert_redirected_to item_draft_path(id: :describe_item, item_id: DraftItem.order(created_at: :asc).last.id)
  end

  test 'should not be able to delete a draft item if you do not own the item' do
    sign_in_as users(:user_regular_two)

    draft_item = draft_items(:draft_item_completed_choose_license_and_visibility_step)

    assert_no_difference('DraftItem.count') do
      delete item_delete_draft_url(item_id: draft_item.id)
    end

    assert_redirected_to root_url
    assert_equal I18n.t('authorization.user_not_authorized'), flash[:alert]
  end

  test 'should be able to delete a draft item if logged in and you own the item' do
    sign_in_as @user

    draft_item = draft_items(:draft_item_completed_choose_license_and_visibility_step)

    assert_difference('DraftItem.count', -1) do
      delete item_delete_draft_url(item_id: draft_item.id)
    end

    assert_redirected_to root_url
  end

end
