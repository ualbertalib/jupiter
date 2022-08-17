require 'test_helper'

class Admin::Theses::FilesControllerTest < ActionDispatch::IntegrationTest

  setup do
    @community = communities(:community_thesis)
    @collection = collections(:collection_thesis)

    @admin = users(:user_admin)
    sign_in_as @admin

    @draft_thesis = draft_theses(:draft_thesis_completed_choose_license_and_visibility_step)
    @draft_thesis.member_of_paths = { community_id: [@community.id], collection_id: [@collection.id] }
    @draft_thesis.save!

    pdf_file = ActiveStorage::Blob.create_and_upload!(
      io: file_fixture('pdf-sample.pdf').open,
      filename: 'pdf-sample.pdf', content_type: 'application/pdf'
    )

    @draft_thesis.files.attach pdf_file

    @file_attachment = fixture_file_upload('/image-sample.jpeg', 'image/jpeg')
  end

  test 'should be able to attach files to a draft thesis' do
    assert_difference('@draft_thesis.files.count', 1) do
      post admin_thesis_files_url(@draft_thesis), params: { file: @file_attachment }, xhr: true
    end

    assert_response :success

    @draft_thesis.reload

    assert_predicate @draft_thesis.files, :attached?
    assert_equal 'pdf-sample.pdf', @draft_thesis.files.first.filename.to_s
    assert_equal 'image-sample.jpeg', @draft_thesis.files.last.filename.to_s
  end

  test 'should be able to remove files from a draft thesis' do
    assert_difference('@draft_thesis.files.count', -1) do
      delete admin_thesis_file_url(@draft_thesis, @draft_thesis.files.first), xhr: true
    end

    assert_response :success

    @draft_thesis.reload
    assert_not @draft_thesis.files.attached?
  end

  test 'should be able to toggle the selection of the draft theses thumbnail' do
    image_file = ActiveStorage::Blob.create_and_upload!(
      io: @file_attachment.open,
      filename: @file_attachment.original_filename, content_type: @file_attachment.content_type
    )

    @draft_thesis.files.attach image_file
    assert_equal 'pdf-sample.pdf', @draft_thesis.thumbnail.filename.to_s

    patch set_thumbnail_admin_thesis_file_url(@draft_thesis, @draft_thesis.files.last), xhr: true

    assert_response :success
    @draft_thesis.reload
    assert_equal 'image-sample.jpeg', @draft_thesis.thumbnail.filename.to_s
  end

end
