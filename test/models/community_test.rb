require 'test_helper'

class CommunityTest < ActiveSupport::TestCase

  include ActiveJob::TestHelper

  test 'visibility callback' do
    c = Community.new(title: 'foo', owner_id: users(:admin).id)
    assert c.valid?
    assert_equal c.visibility, JupiterCore::VISIBILITY_PUBLIC
  end

  test 'needs title' do
    c = Community.new(owner_id: users(:admin).id)
    assert_not c.valid?
    assert_equal "Title can't be blank", c.errors.full_messages.first
  end

  test 'a logo can be attached' do
    # We need to create this LdpObject to get a GlobalID
    c = Community.new(owner_id: users(:admin).id, title: 'Logo test')
                 .unlock_and_fetch_ldp_object(&:save!)
    assert c.to_gid.present?

    c.logo.attach io: File.open(file_fixture('image-sample.jpeg')),
                  filename: 'image-sample.jpeg', content_type: 'image/jpeg'

    assert c.logo.is_a?(ActiveStorage::Attached::One)
    assert_equal c.logo.filename, 'image-sample.jpeg'
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
    c = Community.new(owner_id: users(:admin).id, title: 'Logo test')
                 .unlock_and_fetch_ldp_object(&:save!)
    c.logo.attach io: File.open(file_fixture('image-sample.jpeg')),
                  filename: 'sample1.jpeg', content_type: 'image/jpeg'

    assert_equal c.logo.filename, 'sample1.jpeg'

    c.logo.attach io: File.open(file_fixture('image-sample.jpeg')),
                  filename: 'sample2.jpeg', content_type: 'image/jpeg'
    assert_equal c.logo.filename, 'sample2.jpeg'
  end

end
