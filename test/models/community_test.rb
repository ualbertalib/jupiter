require 'test_helper'

class CommunityTest < ActiveSupport::TestCase

  include ActiveJob::TestHelper

  test 'visibility callback' do
    community = Community.new(title: 'foo', owner_id: users(:admin).id)
    assert community.valid?
    assert_equal community.visibility, JupiterCore::VISIBILITY_PUBLIC
  end

  test 'needs title' do
    community = Community.new(owner_id: users(:admin).id)
    assert_not community.valid?
    assert_equal "Title can't be blank", community.errors.full_messages.first
  end

  test 'a logo can be attached' do
    # We need to create this LdpObject to get a GlobalID
    community = communities(:books)
    assert community.to_gid.present?

    community.logo.attach io: File.open(file_fixture('image-sample.jpeg')),
                  filename: 'image-sample.jpeg', content_type: 'image/jpeg'

    assert community.logo.is_a?(ActiveStorage::Attached::One)
    assert_equal community.logo.filename, 'image-sample.jpeg'
    assert_equal community.logo.blob.content_type, 'image/jpeg'
    assert_equal community.logo.blob.byte_size, 12_086

    # Find file on disk
    key = community.logo.blob.key
    assert key.is_a?(String)
    file_path = ActiveStorage::Blob.service.root + "/#{key[0..1]}/#{key[2..3]}/#{key}"
    assert File.exist?(file_path)
    assert_equal community.logo.blob.checksum, 'GxpIjJsC4KnRoBKNjWnkJA=='
  end

  test 'an updated logo replaces the old one' do
    community = communities(:books)
    community.logo.attach io: File.open(file_fixture('image-sample.jpeg')),
                  filename: 'sample1.jpeg', content_type: 'image/jpeg'

    assert_equal community.logo.filename, 'sample1.jpeg'

    community.logo.attach io: File.open(file_fixture('image-sample.jpeg')),
                  filename: 'sample2.jpeg', content_type: 'image/jpeg'
    assert_equal community.logo.filename, 'sample2.jpeg'
  end

end
