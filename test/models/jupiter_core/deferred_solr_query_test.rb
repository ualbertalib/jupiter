require 'test_helper'

class DeferredSimpleSolrQueryTest < ActiveSupport::TestCase

  @@klass = Class.new(JupiterCore::LockedLdpObject) do
    ldp_object_includes Hydra::Works::WorkBehavior
    has_attribute :title, ::RDF::Vocab::DC.title, solrize_for: [:search, :facet, :sort]
    has_attribute :creator, ::RDF::Vocab::DC.title, solrize_for: [:facet, :sort]
  end

  test 'basic relations' do
    assert_not @@klass.all.present?
    assert_equal @@klass.all.total_count, 0

    assert @@klass.where(title: 'foo').is_a?(JupiterCore::DeferredSimpleSolrQuery)
    assert @@klass.sort(:title).is_a?(JupiterCore::DeferredSimpleSolrQuery)
    assert @@klass.limit(5).is_a?(JupiterCore::DeferredSimpleSolrQuery)
    assert @@klass.offset(5).is_a?(JupiterCore::DeferredSimpleSolrQuery)

    obj = @@klass.new_locked_ldp_object(title: 'foo', owner: users(:regular_user).id,
                                        visibility: JupiterCore::VISIBILITY_PUBLIC)
    another_obj = @@klass.new_locked_ldp_object(title: 'zoo', owner: users(:regular_user).id,
                                                visibility: JupiterCore::VISIBILITY_PUBLIC)
    private_obj = @@klass.new_locked_ldp_object(title: 'boo', owner: users(:regular_user).id,
                                                visibility: JupiterCore::VISIBILITY_PRIVATE)

    obj.unlock_and_fetch_ldp_object(&:save!)
    another_obj.unlock_and_fetch_ldp_object(&:save!)
    private_obj.unlock_and_fetch_ldp_object(&:save!)

    assert @@klass.all.present?
    assert_equal @@klass.all.total_count, 3
    assert @@klass.where(title: 'foo').first.id == obj.id

    assert_equal @@klass.sort(:title, :desc).map(&:id), [another_obj.id, obj.id, private_obj.id]

    # visibility constraints
    assert_equal 2, @@klass.where(visibility: JupiterCore::VISIBILITY_PUBLIC).count
    assert_equal private_obj.id, @@klass.where(visibility: JupiterCore::VISIBILITY_PRIVATE).first.id
  end

  # regression test for #138
  test 'loss of clauses regression when paging' do
    items = @@klass.where(title: 'foo')
    items = items.page 1
    assert items.send(:criteria).include? :where
  end

  # regression test for #137
  test 'setting an absurdly high limit on results by default' do
    items = @@klass.where(title: 'foo')
    assert items.send(:criteria).include? :limit
    assert_equal items.send(:criteria)[:limit], JupiterCore::Search::MAX_RESULTS
  end

  test 'multisort' do
    deferred_query = @@klass.sort(:title).sort(:creator, :desc)

    assert_equal deferred_query.send(:criteria)[:sort].count, 2
    assert_includes deferred_query.send(:criteria)[:sort], 'title_ssi'
    assert_includes deferred_query.send(:criteria)[:sort], 'creator_ssi'

    assert_equal deferred_query.send(:criteria)[:sort_order].count, 2
    assert_includes deferred_query.send(:criteria)[:sort_order], :desc
    assert_includes deferred_query.send(:criteria)[:sort_order], :asc
  end

  test 'sort constraints' do
    assert_raises ArgumentError do
      @@klass.sort(:title, :blah)
    end

    assert_raises ArgumentError do
      @@klass.sort(:asadfg)
    end
  end

end
