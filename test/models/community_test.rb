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

    c.logo.attach io: File.open(Rails.root + 'app/assets/images/mc_360.png'),
                  filename: 'logo_test.png', content_type: 'image/png'

    assert c.logo.is_a?(ActiveStorage::Attached::One)
    # 'name' refers to the attribute of the record, not filename
    assert c.logo.name == :logo
    assert c.logo.record_gid == c.to_gid.to_s
    assert c.logo.blob.filename == 'logo_test.png'
    assert c.logo.blob.content_type == 'image/png'
    assert c.logo.blob.byte_size == 62_432

    # Find file on disk
    key = c.logo.blob.key
    assert key.is_a?(String)
    file_path = ActiveStorage::Blob.service.root + "/#{key[0..1]}/#{key[2..3]}/#{key}"
    assert File.exist?(file_path)
    assert c.logo.blob.checksum == 'yqKitl2Sb8kH0kMfyd3nRg=='
  end

  test 'an updated logo replaces the old one' do
    c = Community.new_locked_ldp_object(owner: users(:admin).id, title: 'Logo test')
                 .unlock_and_fetch_ldp_object(&:save!)
    c.logo.attach io: File.open(Rails.root + 'app/assets/images/mc_360.png'),
                  filename: 'logo1.png', content_type: 'image/png'

    # Assert database records exist
    attachment_id1 = c.logo.id
    blob_id1 = c.logo.blob.id
    assert ActiveStorage::Attachment.where(id: attachment_id1).present?
    assert ActiveStorage::Blob.where(id: blob_id1).present?
    assert c.logo.blob.filename == 'logo1.png'

    # Assert file exists
    key = c.logo.blob.key
    file_path1 = ActiveStorage::Blob.service.root + "/#{key[0..1]}/#{key[2..3]}/#{key}"
    assert File.exist?(file_path1)

    # Attach new logo. Note, purging of logo happens as a background job.
    perform_enqueued_jobs do
      c.logo.attach io: File.open(Rails.root + 'app/assets/images/mc_360.png'),
                    filename: 'logo2.png', content_type: 'image/png'
    end

    # Assert new database records exist
    attachment_id2 = c.logo.id
    blob_id2 = c.logo.blob.id
    refute attachment_id1 == attachment_id2
    refute blob_id1 == blob_id2
    assert ActiveStorage::Attachment.where(id: attachment_id2).present?
    assert ActiveStorage::Blob.where(id: blob_id2).present?
    assert c.logo.blob.filename == 'logo2.png'

    # Assert old database records are gone
    refute ActiveStorage::Attachment.where(id: attachment_id1).present?
    refute ActiveStorage::Blob.where(id: blob_id1).present?

    # Assert new file exists and isn't the same as old file
    key = c.logo.blob.key
    file_path2 = ActiveStorage::Blob.service.root + "/#{key[0..1]}/#{key[2..3]}/#{key}"
    assert File.exist?(file_path2)
    refute file_path1 == file_path2

    # Assert old file is gone
    refute File.exist?(file_path1)
  end

end
