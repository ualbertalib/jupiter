require 'test_helper'

class DeferredSolrQueryTest < ActiveSupport::TestCase

  @@klass = Class.new(JupiterCore::LockedLdpObject) do
    ldp_object_includes Hydra::Works::WorkBehavior
    has_attribute :title, ::RDF::Vocab::DC.title, solrize_for: [:search, :facet, :sort]
    has_attribute :creator, ::RDF::Vocab::DC.title, solrize_for: [:facet]
  end

  test 'basic relations' do
    assert_not @@klass.all.present?
    assert_equal @@klass.all.total_count, 0

    assert @@klass.where(title: 'foo').is_a?(JupiterCore::DeferredSolrQuery)
    assert @@klass.sort(:title).is_a?(JupiterCore::DeferredSolrQuery)
    assert @@klass.limit(5).is_a?(JupiterCore::DeferredSolrQuery)
    assert @@klass.offset(5).is_a?(JupiterCore::DeferredSolrQuery)

    obj = @@klass.new_locked_ldp_object(title: 'foo', owner: users(:regular_user).id,
                                        visibility: JupiterCore::VISIBILITY_PUBLIC)
    another_obj = @@klass.new_locked_ldp_object(title: 'zoo', owner: users(:regular_user).id,
                                                visibility: JupiterCore::VISIBILITY_PUBLIC)

    obj.unlock_and_fetch_ldp_object(&:save!)
    another_obj.unlock_and_fetch_ldp_object(&:save!)

    assert @@klass.all.present?
    assert_equal @@klass.all.total_count, 2
    assert @@klass.where(title: 'foo').first.id == obj.id

    assert_equal @@klass.sort(:title, :desc).map(&:id), [another_obj.id, obj.id]
  end

  # regression test for #138
  test 'loss of clauses regression when paging' do
    items = @@klass.where(title: 'foo')
    items = items.page 1
    assert items.send(:criteria).include? :where
  end

  test 'sort constraints' do
    assert_raises ArgumentError do
      @@klass.sort(:title, :blah)
    end

    assert_raises ArgumentError do
      @@klass.sort(:creator)
    end

    assert_raises ArgumentError do
      @@klass.sort(:asadfg)
    end
  end

end
