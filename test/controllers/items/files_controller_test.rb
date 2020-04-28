require 'test_helper'

class Items::FilesControllerTest < ActionDispatch::IntegrationTest

  setup do
    @community = communities(:books)
    @collection = collections(:fantasy_books)

    @user = users(:regular)
    sign_in_as @user

    @draft_item = draft_items(:completed_choose_license_and_visibility_step)
    @draft_item.member_of_paths = { 'community_id': [@community.id], 'collection_id': [@collection.id] }
    @draft_item.save!

    pdf_file = ActiveStorage::Blob.create_after_upload!(
      io: file_fixture('pdf-sample.pdf').open,
      filename: 'pdf-sample.pdf', content_type: 'application/pdf'
    )

    @draft_item.files.attach pdf_file

    @file_attachment = fixture_file_upload('/files/image-sample.jpeg', 'image/jpeg')
  end

  test 'should be able to attach files to a draft item' do
    assert_difference('ActiveStorage::Attachment.count', 1) do
      post item_files_url(@draft_item), params: { file: @file_attachment }, xhr: true
    end

    assert_response :success

    @draft_item.reload

    assert @draft_item.files.attached?
    assert_equal 2, @draft_item.files.count
    assert_equal 'pdf-sample.pdf', @draft_item.files.first.filename.to_s
    assert_equal 'image-sample.jpeg', @draft_item.files.last.filename.to_s
  end

  test 'should be able to remove files from a draft item' do
    assert_difference('ActiveStorage::Attachment.count', -1) do
      delete item_file_url(@draft_item, @draft_item.files.first), xhr: true
    end

    assert_response :success

    @draft_item.reload

    assert_not @draft_item.files.attached?
    assert_equal 0, @draft_item.files.count
  end

  test 'should be able to toggle the selection of the draft items thumbnail' do
    image_file = ActiveStorage::Blob.create_after_upload!(
      io: @file_attachment.open,
      filename: @file_attachment.original_filename, content_type: @file_attachment.content_type
    )

    @draft_item.files.attach image_file
    assert_equal 'pdf-sample.pdf', @draft_item.thumbnail.filename.to_s

    patch set_thumbnail_item_file_url(@draft_item, @draft_item.files.last), xhr: true

    assert_response :success
    @draft_item.reload
    assert_equal 'image-sample.jpeg', @draft_item.thumbnail.filename.to_s
  end

end
