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

  test 'attaching files' do
    file = ActionDispatch::Http::UploadedFile.new(filename: 'image-sample.jpeg',
                                                  content_type: 'image/jpeg',
                                                  tempfile: File.open(file_fixture('image-sample.jpeg')))

    # It seems unfortunate as a side-effect of improved item validations, we need to create these in tests that
    # don't care about them...
    community = Community.create!(title: 'Community', owner_id: users(:admin).id)
    collection = Collection.create!(title: 'foo', owner_id: users(:regular).id,
                                                  community_id: community.id)

    item = Item.new(visibility: JupiterCore::VISIBILITY_PUBLIC,
                                               owner_id: users(:admin).id, title: 'Fancy Item',
                                               creators: ['Joe Blow'],
                                               created: '1938-01-02',
                                               languages: [CONTROLLED_VOCABULARIES[:language].english],
                                               item_type: CONTROLLED_VOCABULARIES[:item_type].article,
                                               publication_status:
                                               [CONTROLLED_VOCABULARIES[:publication_status].published],
                                               license: CONTROLLED_VOCABULARIES[:license].attribution_4_0_international,
                                               subject: ['Items'])
    item.unlock_and_fetch_ldp_object do |unlocked_item|
      unlocked_item.add_to_path(community.id, collection.id)
      unlocked_item.save!
      Sidekiq::Testing.inline! do
        item.add_and_ingest_files([file])
      end
    end
    file_set = nil
    # we need to call this deprecated method to verify the model is working
    ActiveSupport::Deprecation.silence do
      file_set = item.files.first
    end
    assert_not file_set.nil?
    assert_equal file_set.blob.filename.to_s, 'image-sample.jpeg'
    item.set_thumbnail(item.files.first)
    assert item.thumbnail_url.present?
  end

end
