require 'test_helper'

class ThesisTest < ActiveSupport::TestCase

  test 'a valid item can be constructed' do
    community = Community.new_locked_ldp_object(title: 'Community', owner: 1,
                                                visibility: JupiterCore::VISIBILITY_PUBLIC)
    community.unlock_and_fetch_ldp_object(&:save!)
    collection = Collection.new_locked_ldp_object(title: 'Collection', owner: 1,
                                                  visibility: JupiterCore::VISIBILITY_PUBLIC,
                                                  community_id: community.id)
    collection_uri = nil
    collection.unlock_and_fetch_ldp_object do |unlocked_collection|
      unlocked_collection.save!
      collection_uri = unlocked_collection.uri
    end
    thesis = Thesis.new_locked_ldp_object(title: 'Thesis', owner: 1, visibility: JupiterCore::VISIBILITY_PUBLIC,
                                          dissertant: 'Joe Blow',
                                          graduation_date: 'Fall 2013')
    thesis.unlock_and_fetch_ldp_object do |unlocked_thesis|
      unlocked_thesis.add_to_path(community.id, collection.id)
      unlocked_thesis.save!
      # Reload needed for dump below
      unlocked_thesis.reload

      # Dump some triples for sanity checks
      triples = unlocked_thesis.resource.dump(:ntriples)
      # Ensure correct type triple was saved
      assert_match('<http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <http://purl.org/ontology/bibo/Thesis>',
                   triples)
      # Ensure `memberOf` was set correctly to collection ID:
      assert_match("<http://pcdm.org/models#memberOf> <#{collection_uri}>", triples)
    end
    assert thesis.valid?
  end

  test 'there is no default visibility' do
    thesis = Thesis.new_locked_ldp_object

    assert_nil thesis.visibility
  end

  test 'unknown visibilities are not valid' do
    thesis = Thesis.new_locked_ldp_object

    thesis.unlock_and_fetch_ldp_object do |unlocked_thesis|
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
    thesis = Thesis.new_locked_ldp_object
    assert_nothing_raised do
      thesis.unlock_and_fetch_ldp_object do |unlocked_thesis|
        unlocked_thesis.graduation_date = 'before 1997 or after 2084'
      end
    end
    assert_not thesis.valid?
    assert_equal '1997', thesis.sort_year
  end

  test 'embargo_end_date must be present if visibility is embargo' do
    thesis = Thesis.new_locked_ldp_object
    thesis.unlock_and_fetch_ldp_object do |unlocked_thesis|
      unlocked_thesis.visibility = Thesis::VISIBILITY_EMBARGO
    end

    assert_not thesis.valid?
    assert thesis.errors[:embargo_end_date].present?
    assert_includes thesis.errors[:embargo_end_date], "can't be blank"
  end

  test 'embargo_end_date must be blank for non-embargo visibilities' do
    thesis = Thesis.new_locked_ldp_object
    thesis.unlock_and_fetch_ldp_object do |unlocked_thesis|
      unlocked_thesis.visibility = JupiterCore::VISIBILITY_PUBLIC
      unlocked_thesis.embargo_end_date = '1992-02-01'
    end

    assert_not thesis.valid?
    assert thesis.errors[:embargo_end_date].present?
    assert_includes thesis.errors[:embargo_end_date], 'must be blank'

    refute thesis.errors[:visibility].present?
  end

  test 'visibility_after_embargo must be present if visibility is embargo' do
    thesis = Thesis.new_locked_ldp_object
    thesis.unlock_and_fetch_ldp_object do |unlocked_thesis|
      unlocked_thesis.visibility = Thesis::VISIBILITY_EMBARGO
    end

    assert_not thesis.valid?
    assert thesis.errors[:visibility_after_embargo].present?
    assert_includes thesis.errors[:visibility_after_embargo], "can't be blank"
  end

  test 'visibility_after_embargo must be blank for non-embargo visibilities' do
    thesis = Thesis.new_locked_ldp_object
    thesis.unlock_and_fetch_ldp_object do |unlocked_thesis|
      unlocked_thesis.visibility = JupiterCore::VISIBILITY_PUBLIC
      unlocked_thesis.visibility_after_embargo = CONTROLLED_VOCABULARIES[:visibility].draft
    end

    assert_not thesis.valid?
    assert thesis.errors[:visibility_after_embargo].present?
    assert_includes thesis.errors[:visibility_after_embargo], 'must be blank'
    # Make sure no controlled vocabulary error
    refute_includes thesis.errors[:visibility_after_embargo], 'is not recognized'

    refute thesis.errors[:visibility].present?
  end

  test 'visibility_after_embargo must be from the controlled vocabulary' do
    thesis = Thesis.new_locked_ldp_object
    thesis.unlock_and_fetch_ldp_object do |unlocked_thesis|
      unlocked_thesis.visibility = Thesis::VISIBILITY_EMBARGO
      unlocked_thesis.visibility_after_embargo = 'whatever'
    end

    assert_not thesis.valid?
    assert thesis.errors[:visibility_after_embargo].present?
    assert_includes thesis.errors[:visibility_after_embargo], 'is not recognized'
    refute thesis.errors[:visibility].present?
  end

  test '#add_to_path assigns paths properly' do
    thesis = Thesis.new_locked_ldp_object
    community_id = generate_random_string
    collection_id = generate_random_string

    thesis.unlock_and_fetch_ldp_object do |unlocked_thesis|
      unlocked_thesis.add_to_path(community_id, collection_id)
    end

    assert_includes thesis.member_of_paths, "#{community_id}/#{collection_id}"
  end

  test 'member_of_paths is not a display attribute' do
    assert_not_includes Thesis.display_attribute_names, :member_of_paths
  end

  test 'a community/collection path must be present' do
    thesis = Thesis.new_locked_ldp_object

    assert_not thesis.valid?
    assert_includes thesis.errors[:member_of_paths], "can't be blank"
  end

  test 'community/collection must exist' do
    thesis = Thesis.new_locked_ldp_object
    community_id = generate_random_string
    collection_id = generate_random_string
    thesis.unlock_and_fetch_ldp_object do |unlocked|
      unlocked.add_to_path(community_id, collection_id)
    end

    assert_not thesis.valid?
    assert_includes thesis.errors[:member_of_paths],
                    I18n.t('activemodel.errors.models.ir_thesis.attributes.member_of_paths.community_not_found',
                           id: community_id)
    assert_includes thesis.errors[:member_of_paths],
                    I18n.t('activemodel.errors.models.ir_thesis.attributes.member_of_paths.collection_not_found',
                           id: collection_id)
  end

  test 'item_type_with_status_code gets set correctly' do
    thesis = Thesis.new_locked_ldp_object
    assert_equal thesis.item_type_with_status_code, 'thesis'
  end

  test 'a title is required' do
    thesis = Thesis.new_locked_ldp_object
    assert_not thesis.valid?
    assert_includes thesis.errors[:title], "can't be blank"
  end

  test 'a dissertant is required' do
    thesis = Thesis.new_locked_ldp_object
    assert_not thesis.valid?
    assert_includes thesis.errors[:dissertant], "can't be blank"
  end

  test 'a graduation date is required' do
    thesis = Thesis.new_locked_ldp_object
    assert_not thesis.valid?
    assert_includes thesis.errors[:graduation_date], "can't be blank"
  end

  test 'a sort year is required' do
    thesis = Thesis.new_locked_ldp_object
    assert_not thesis.valid?
    assert_includes thesis.errors[:sort_year], "can't be blank"
  end

  test 'a sort year is derived from graduation date' do
    thesis = Thesis.new_locked_ldp_object(graduation_date: 'Fall 2015')
    thesis.valid?
    refute thesis.errors[:sort_year].present?
    assert_equal thesis.sort_year, '2015'
  end

end
