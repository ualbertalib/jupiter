require 'test_helper'

class EmbargoExpiryJobTest < ActiveJob::TestCase

  def before_all
    super
    @community = locked_ldp_fixture(Community, :nice).unlock_and_fetch_ldp_object(&:save!)
    @collection = locked_ldp_fixture(Collection, :nice).unlock_and_fetch_ldp_object(&:save!)
  end

  test 'that job transitions only expired item embargos into proper state' do
    expired_item = Item.new(
      owner_id: 1,
      title: 'Fancy Item',
      creators: ['Joe Blow'],
      created: 'Fall 2017',
      languages: [CONTROLLED_VOCABULARIES[:language].english],
      license: CONTROLLED_VOCABULARIES[:license].attribution_4_0_international,
      item_type: CONTROLLED_VOCABULARIES[:item_type].article,
      publication_status: [CONTROLLED_VOCABULARIES[:publication_status].published],
      subject: ['Fancy things'],
      visibility: ItemProperties::VISIBILITY_EMBARGO,
      embargo_end_date: 2.days.ago.to_date,
      visibility_after_embargo: CONTROLLED_VOCABULARIES[:visibility].public
    ).unlock_and_fetch_ldp_object do |uo|
      uo.add_to_path(@community.id, @collection.id)
      uo.save!
    end

    not_expired_item = Item.new(
      owner_id: 1,
      title: 'Fancy Item',
      creators: ['Joe Blow'],
      created: 'Fall 2017',
      languages: [CONTROLLED_VOCABULARIES[:language].english],
      license: CONTROLLED_VOCABULARIES[:license].attribution_4_0_international,
      item_type: CONTROLLED_VOCABULARIES[:item_type].article,
      publication_status: [CONTROLLED_VOCABULARIES[:publication_status].published],
      subject: ['Fancy things'],
      visibility: ItemProperties::VISIBILITY_EMBARGO,
      embargo_end_date: 2.days.from_now.to_date,
      visibility_after_embargo: CONTROLLED_VOCABULARIES[:visibility].public
    ).unlock_and_fetch_ldp_object do |uo|
      uo.add_to_path(@community.id, @collection.id)
      uo.save!
    end

    EmbargoExpiryJob.perform_now

    expired_item.unlock_and_fetch_ldp_object(&:reload)
    not_expired_item.unlock_and_fetch_ldp_object(&:reload)

    assert_equal expired_item.visibility, JupiterCore::VISIBILITY_PUBLIC
    assert_nil expired_item.visibility_after_embargo
    assert_nil expired_item.embargo_end_date

    assert_equal not_expired_item.visibility, ItemProperties::VISIBILITY_EMBARGO
    assert_equal not_expired_item.visibility_after_embargo, CONTROLLED_VOCABULARIES[:visibility].public
    assert_equal not_expired_item.embargo_end_date, 2.days.from_now.to_date
  end

  test 'that job transitions expired thesis embargos into proper state' do
    expired_thesis = Thesis.new(
      title: 'thesis blocking deletion',
      owner_id: 1,
      dissertant: 'Joe Blow',
      graduation_date: '2017-03-31',
      visibility: ItemProperties::VISIBILITY_EMBARGO,
      embargo_end_date: 2.days.ago.to_date,
      visibility_after_embargo: CONTROLLED_VOCABULARIES[:visibility].public
    ).unlock_and_fetch_ldp_object do |unlocked_thesis|
      unlocked_thesis.add_to_path(@community.id, @collection.id)
      unlocked_thesis.save!
    end

    not_expired_thesis = Thesis.new(
      title: 'thesis blocking deletion',
      owner_id: 1,
      dissertant: 'Joe Blow',
      graduation_date: '2017-03-31',
      visibility: ItemProperties::VISIBILITY_EMBARGO,
      embargo_end_date: 2.days.from_now.to_date,
      visibility_after_embargo: CONTROLLED_VOCABULARIES[:visibility].public
    ).unlock_and_fetch_ldp_object do |unlocked_thesis|
      unlocked_thesis.add_to_path(@community.id, @collection.id)
      unlocked_thesis.save!
    end

    EmbargoExpiryJob.perform_now

    expired_thesis.unlock_and_fetch_ldp_object(&:reload)
    not_expired_thesis.unlock_and_fetch_ldp_object(&:reload)

    assert_equal expired_thesis.visibility, JupiterCore::VISIBILITY_PUBLIC
    assert_nil expired_thesis.visibility_after_embargo
    assert_nil expired_thesis.embargo_end_date

    assert_equal not_expired_thesis.visibility, ItemProperties::VISIBILITY_EMBARGO
    assert_equal not_expired_thesis.visibility_after_embargo, CONTROLLED_VOCABULARIES[:visibility].public
    assert_equal not_expired_thesis.embargo_end_date, 2.days.from_now.to_date
  end

end
