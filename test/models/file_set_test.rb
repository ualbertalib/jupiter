require 'test_helper'

class FileSetTest < ActiveSupport::TestCase

  # TODO: should visibility be a concern here, or does it just inherit from parent item?
  test 'there is no default visibility' do
    file_set = FileSet.new_locked_ldp_object

    assert_nil file_set.visibility
  end

  test 'unknown visibilities are not valid' do
    file_set = FileSet.new_locked_ldp_object

    file_set.unlock_and_fetch_ldp_object do |unlocked_file_set|
      unlocked_file_set.visibility = 'some_fake_visibility'
    end

    assert_not file_set.valid?
    assert file_set.errors[:visibility].present?
    assert_includes file_set.errors[:visibility], 'some_fake_visibility is not a known visibility'
  end

  test '#add_new_to_item' do
    file = ActionDispatch::Http::UploadedFile.new(filename: 'logo_test.png',
                                                  content_type: 'image/png',
                                                  tempfile: File.open(Rails.root + 'app/assets/images/mc_360.png'))

    item = Item.new_locked_ldp_object(visibility: 'public', owner: 1)
    item.unlock_and_fetch_ldp_object do |unlocked_item|
      unlocked_item.save!
      FileSet.add_new_to_item(file, unlocked_item)
      unlocked_item.save!
    end
    file_set = item.file_sets.first
    refute file_set.nil?
    assert file_set.original_file_name == 'logo_test.png'
    assert file_set.original_mime_type == 'image/png'
    assert file_set.original_size_bytes == 62_432
    assert file_set.original_uri =~ /http.*fcrepo\/rest\/.*#{file_set.id}\/files\/.*/
  end

end
