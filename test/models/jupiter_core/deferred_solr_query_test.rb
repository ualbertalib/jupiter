require 'test_helper'

class DeferredSimpleSolrQueryTest < ActiveSupport::TestCase

  @@exporter = Class.new(Exporters::Solr::BaseExporter) do
    index :title, role: [:search, :facet, :sort]
    index :creator, role: [:facet, :sort]
  end

  @@klass = Class.new(JupiterCore::LockedLdpObject) do
    ldp_object_includes Hydra::Works::WorkBehavior
    has_solr_exporter @@exporter

    has_attribute :title, ::RDF::Vocab::DC.title, solrize_for: [:search, :facet, :sort]
    has_attribute :creator, ::RDF::Vocab::DC.title, solrize_for: [:facet, :sort]

    default_sort index: :creator, direction: :desc
  end

  test 'basic relations' do
    assert_not @@klass.all.present?
    assert_equal @@klass.all.total_count, 0

    assert @@klass.where(title: 'foo').is_a?(JupiterCore::DeferredSimpleSolrQuery)
    assert @@klass.order(:title).is_a?(JupiterCore::DeferredSimpleSolrQuery)
    assert @@klass.limit(5).is_a?(JupiterCore::DeferredSimpleSolrQuery)
    assert @@klass.offset(5).is_a?(JupiterCore::DeferredSimpleSolrQuery)

    obj = @@klass.new_locked_ldp_object(title: 'foo', owner_id: users(:regular).id,
                                        visibility: JupiterCore::VISIBILITY_PUBLIC)
    another_obj = @@klass.new_locked_ldp_object(title: 'zoo', owner_id: users(:regular).id,
                                                visibility: JupiterCore::VISIBILITY_PUBLIC)
    private_obj = @@klass.new_locked_ldp_object(title: 'boo', owner_id: users(:regular).id,
                                                visibility: JupiterCore::VISIBILITY_PRIVATE)

    obj.unlock_and_fetch_ldp_object(&:save!)
    another_obj.unlock_and_fetch_ldp_object(&:save!)
    private_obj.unlock_and_fetch_ldp_object(&:save!)

    assert @@klass.all.present?
    assert_equal @@klass.all.total_count, 3
    assert @@klass.where(title: 'foo').first.id == obj.id

    assert_equal @@klass.order(title: :desc).map(&:id), [another_obj.id, obj.id, private_obj.id]

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

  test 'sorting by unknown attributes falls back to defaults' do
    items = @@klass.order(blergh: :foobar)
    assert_equal :creator, items.used_sort_index
    assert_equal :desc, items.used_sort_order
  end

end
