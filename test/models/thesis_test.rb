require 'test_helper'

class ThesisTest < ActiveSupport::TestCase

  test 'a valid item can be constructed' do
    admin = users(:admin)
    community = communities(:books)
    collection = collections(:fantasy_books)
    assert_difference('Thesis.count') do
      thesis = Thesis.new(title: 'Thesis', owner_id: admin.id, visibility: JupiterCore::VISIBILITY_PUBLIC,
                          dissertant: 'Joe Blow',
                          departments: ['Physics', 'Non-physics'],
                          supervisors: ['Billy (Physics)', 'Sally (Non-physics)'],
                          graduation_date: 'Fall 2013')
      thesis.tap do |unlocked_thesis|
        unlocked_thesis.add_to_path(community.id, collection.id)
        unlocked_thesis.save!
      end
    end
    assert thesis.valid?
  end

  test 'there is no default visibility' do
    thesis = Thesis.new

    assert_nil thesis.visibility
  end

  test 'unknown visibilities are not valid' do
    thesis = Thesis.new

    thesis.tap do |unlocked_thesis|
      unlocked_thesis.visibility = 'some_fake_visibility'
    end

    assert_not thesis.valid?
    assert thesis.errors[:visibility].present?
    assert_includes thesis.errors[:visibility], 'some_fake_visibility is not a known visibility'
  end

  test 'embargo is a valid visibility for theses' do
    assert_includes Thesis.valid_visibilities, Thesis::VISIBILITY_EMBARGO
  end

  test 'graduation date allows fuzzy dates' do
    thesis = Thesis.new
    assert_nothing_raised do
      thesis.tap do |unlocked_thesis|
        unlocked_thesis.graduation_date = 'before 1997 or after 2084'
      end
    end
    assert_not thesis.valid?
    assert_equal 1997, thesis.sort_year
  end

  test 'embargo_end_date must be present if visibility is embargo' do
    thesis = Thesis.new
    thesis.tap do |unlocked_thesis|
      unlocked_thesis.visibility = Thesis::VISIBILITY_EMBARGO
    end

    assert_not thesis.valid?
    assert thesis.errors[:embargo_end_date].present?
    assert_includes thesis.errors[:embargo_end_date], "can't be blank"
  end

  test 'embargo_end_date must be blank for non-embargo visibilities' do
    thesis = Thesis.new
    thesis.tap do |unlocked_thesis|
      unlocked_thesis.visibility = JupiterCore::VISIBILITY_PUBLIC
      unlocked_thesis.embargo_end_date = '1992-02-01'
    end

    assert_not thesis.valid?
    assert thesis.errors[:embargo_end_date].present?
    assert_includes thesis.errors[:embargo_end_date], 'must be blank'

    assert_not thesis.errors[:visibility].present?
  end

  test 'visibility_after_embargo must be present if visibility is embargo' do
    thesis = Thesis.new
    thesis.tap do |unlocked_thesis|
      unlocked_thesis.visibility = Thesis::VISIBILITY_EMBARGO
    end

    assert_not thesis.valid?
    assert thesis.errors[:visibility_after_embargo].present?
    assert_includes thesis.errors[:visibility_after_embargo], "can't be blank"
  end

  test 'visibility_after_embargo must be blank for non-embargo visibilities' do
    thesis = Thesis.new
    thesis.tap do |unlocked_thesis|
      unlocked_thesis.visibility = JupiterCore::VISIBILITY_PUBLIC
      unlocked_thesis.visibility_after_embargo = ControlledVocabulary.jupiter_core.visibility.draft
    end

    assert_not thesis.valid?
    assert thesis.errors[:visibility_after_embargo].present?
    assert_includes thesis.errors[:visibility_after_embargo], 'must be blank'
    # Make sure no controlled vocabulary error
    assert_not_includes thesis.errors[:visibility_after_embargo], 'is not recognized'

    assert_not thesis.errors[:visibility].present?
  end

  test 'visibility_after_embargo must be from the controlled vocabulary' do
    thesis = Thesis.new
    thesis.tap do |unlocked_thesis|
      unlocked_thesis.visibility = Thesis::VISIBILITY_EMBARGO
      unlocked_thesis.visibility_after_embargo = 'whatever'
    end

    assert_not thesis.valid?
    assert thesis.errors[:visibility_after_embargo].present?
    assert_includes thesis.errors[:visibility_after_embargo], 'whatever is not a known visibility'
    assert_not thesis.errors[:visibility].present?
  end

  test '#add_to_path assigns paths properly' do
    thesis = Thesis.new
    community_id = generate_random_string
    collection_id = generate_random_string

    thesis.tap do |unlocked_thesis|
      unlocked_thesis.add_to_path(community_id, collection_id)
    end

    assert_includes thesis.member_of_paths, "#{community_id}/#{collection_id}"
  end

  test 'a community/collection path must be present' do
    thesis = Thesis.new

    assert_not thesis.valid?
    assert_includes thesis.errors[:member_of_paths], "can't be blank"
  end

  test 'community/collection must exist' do
    thesis = Thesis.new
    community_id = generate_random_string
    collection_id = generate_random_string
    thesis.tap do |unlocked|
      unlocked.add_to_path(community_id, collection_id)
    end

    assert_not thesis.valid?
    assert_includes thesis.errors[:member_of_paths],
                    I18n.t('activerecord.errors.models.thesis.attributes.member_of_paths.community_not_found',
                           id: community_id)
    assert_includes thesis.errors[:member_of_paths],
                    I18n.t('activerecord.errors.models.thesis.attributes.member_of_paths.collection_not_found',
                           id: collection_id)
  end

  test 'item_type_with_status_code gets set correctly' do
    thesis = Thesis.new
    assert_equal(:thesis, thesis.item_type_with_status_code)
  end

  test 'a title is required' do
    thesis = Thesis.new
    assert_not thesis.valid?
    assert_includes thesis.errors[:title], "can't be blank"
  end

  test 'a dissertant is required' do
    thesis = Thesis.new
    assert_not thesis.valid?
    assert_includes thesis.errors[:dissertant], "can't be blank"
  end

  test 'a graduation date is required' do
    thesis = Thesis.new
    assert_not thesis.valid?
    assert_includes thesis.errors[:graduation_date], "can't be blank"
  end

  test 'a sort year is required' do
    thesis = Thesis.new
    assert_not thesis.valid?
    assert_includes thesis.errors[:sort_year], "can't be blank"
  end

  test 'a sort year is derived from graduation date' do
    thesis = Thesis.new(graduation_date: 'Fall 2015')
    thesis.valid?
    assert_not thesis.errors[:sort_year].present?
    assert_equal(2015, thesis.sort_year)
  end

end
