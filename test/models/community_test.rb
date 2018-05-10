require 'test_helper'

class CommunityTest < ActiveSupport::TestCase

  include ActiveJob::TestHelper

  test 'visibility callback' do
    c = Community.new_locked_ldp_object(title: 'foo', owner: users(:admin).id)
    assert c.valid?
    assert_equal c.visibility, JupiterCore::VISIBILITY_PUBLIC
  end

  test 'needs title' do
    c = Community.new_locked_ldp_object(owner: users(:admin).id)
    refute c.valid?
    assert_equal "Title can't be blank", c.errors.full_messages.first
  end

  test 'a logo can be attached' do
    # We need to create this LdpObject to get a GlobalID
    c = Community.new_locked_ldp_object(owner: users(:admin).id, title: 'Logo test')
                 .unlock_and_fetch_ldp_object(&:save!)
    assert c.to_gid.present?

    c.logo.attach io: File.open(file_fixture('image-sample.jpeg')),
                  filename: 'image-sample.jpeg', content_type: 'image/jpeg'

    assert c.logo.is_a?(ActiveStorage::Attached::One)
    assert_equal c.logo.blob.filename, 'image-sample.jpeg'
    assert_equal c.logo.blob.content_type, 'image/jpeg'
    assert_equal c.logo.blob.byte_size, 12_086

    # Find file on disk
    key = c.logo.blob.key
    assert key.is_a?(String)
    file_path = ActiveStorage::Blob.service.root + "/#{key[0..1]}/#{key[2..3]}/#{key}"
    assert File.exist?(file_path)
    assert_equal c.logo.blob.checksum, 'GxpIjJsC4KnRoBKNjWnkJA=='
  end

  test 'an updated logo replaces the old one' do
    c = Community.new_locked_ldp_object(owner: users(:admin).id, title: 'Logo test')
                 .unlock_and_fetch_ldp_object(&:save!)
    c.logo.attach io: File.open(file_fixture('image-sample.jpeg')),
                  filename: 'sample1.jpeg', content_type: 'image/jpeg'

    # Assert database records exist
    attachment_id1 = c.logo.id
    blob_id1 = c.logo.blob.id
    assert ActiveStorage::Attachment.where(id: attachment_id1).present?
    assert ActiveStorage::Blob.where(id: blob_id1).present?
    assert_equal c.logo.blob.filename, 'sample1.jpeg'

    # Assert file exists
    key = c.logo.blob.key
    file_path1 = ActiveStorage::Blob.service.root + "/#{key[0..1]}/#{key[2..3]}/#{key}"
    assert File.exist?(file_path1)

    # Attach new logo. Note, purging of logo happens as a background job.
    perform_enqueued_jobs do
      c.logo.attach io: File.open(file_fixture('image-sample.jpeg')),
                    filename: 'sample2.jpeg', content_type: 'image/jpeg'
    end

    # Assert new database records exist
    attachment_id2 = c.logo.id
    blob_id2 = c.logo.blob.id
    refute_equal attachment_id1, attachment_id2
    refute_equal blob_id1, blob_id2
    assert ActiveStorage::Attachment.where(id: attachment_id2).present?
    assert ActiveStorage::Blob.where(id: blob_id2).present?
    assert_equal c.logo.blob.filename, 'sample2.jpeg'

    # Assert old database records are gone
    refute ActiveStorage::Attachment.where(id: attachment_id1).present?
    refute ActiveStorage::Blob.where(id: blob_id1).present?

    # Assert new file exists and isn't the same as old file
    key = c.logo.blob.key
    file_path2 = ActiveStorage::Blob.service.root + "/#{key[0..1]}/#{key[2..3]}/#{key}"
    assert File.exist?(file_path2)
    refute_equal file_path1, file_path2

    # Assert old file is gone
    refute File.exist?(file_path1)
  end

end
