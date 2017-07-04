require 'test_helper'

class LockedLdpObjectTest < ActiveSupport::TestCase
  @@klass = Class.new(JupiterCore::LockedLdpObject) do
    ldp_object_includes Hydra::Works::WorkBehavior
    has_attribute :title, ::RDF::Vocab::DC.title, solrize_for: [:search, :facet]
    has_multival_attribute :member_of_paths, ::UalibTerms.path, solrize_for: :pathing

    solr_calculated_attribute :my_solr_doc_attr, solrize_for: :search do
      'a_test_value'
    end

    def locked_method_shouldnt_mutate(attempted_title)
      self.title = attempted_title
    end

    def safe_locked_method
      return "Title is: #{self.title}"
    end

    unlocked do
      def unlocked_method_can_mutate(attempted_title)
        self.title = attempted_title
      end

      def unlocked_method_dont_let_locked_methods_mutate(attempted_title)
        locked_method_shouldnt_mutate(attempted_title)
      end
    end
  end

  # this fails if the call to super doesn't happen in JupiterCore::LockedLdpObject.inherited
  def test_inheritance_is_tracking_properly
    assert_includes JupiterCore::LockedLdpObject.descendants, @@klass
  end

  def test_safe_attributes_never_includes_id
    JupiterCore::LockedLdpObject.descendants.each do |klass|
      assert_not_includes klass.safe_attributes, :id
    end
  end

  def test_shared_indexer_is_used
    assert_equal @@klass.send(:derived_af_class).indexer, JupiterCore::Indexer
  end

  def test_af_object_included_named_modules
    assert @@klass.send(:derived_af_class).include? Hydra::Works::WorkBehavior
  end

  def test_attribute_definitions
    assert_equal @@klass.attribute_names.sort, [:id, :member_of_paths, :title]
  end

  def test_attribute_metadata
    title_metadata = @@klass.attribute_metadata(:title)

    assert_instance_of Hash, title_metadata
    assert_equal ::RDF::Vocab::DC.title, title_metadata[:predicate]
    assert_equal :string, title_metadata[:type]
    assert_not title_metadata[:multiple]
    assert_equal [:search, :facet], title_metadata[:solrize_for]
    assert_equal ['title_tesim', 'title_sim'], title_metadata[:solr_names]

    assert @@klass.attribute_metadata(:member_of_paths)[:multiple]
  end

  def test_solr_calculated_attributes
    obj = @@klass.new_locked_ldp_object(title: 'A Work')

    obj.unlock_and_fetch_ldp_object do |uo|
      solr_doc = uo.to_solr
      assert solr_doc.key? 'my_solr_doc_attr_tesim'
      assert_includes solr_doc['my_solr_doc_attr_tesim'], 'a_test_value'
    end
  end

  def test_reverse_solr_name_lookup
    assert_equal :title, @@klass.solr_name_to_attribute_name('title_tesim')
    assert_equal :member_of_paths, @@klass.solr_name_to_attribute_name('member_of_paths_dpsim')
  end

  def test_default_constructor_is_private
    assert_raises ::NoMethodError do
      @@klass.new
    end
  end

  def test_locked_object_enforcement
    obj = @@klass.new_locked_ldp_object(title: 'A Work')

    assert_equal 'A Work', obj.title
    assert_raises JupiterCore::LockedInstanceError do
      obj.title = 'asdf'
    end

    assert_raises JupiterCore::LockedInstanceError do
      obj.locked_method_shouldnt_mutate('asdf')
    end

    assert_raises JupiterCore::LockedInstanceError do
      obj.unlocked_method_can_mutate('asdf')
    end

    assert_raises JupiterCore::LockedInstanceError do
      obj.unlock_and_fetch_ldp_object {|uo| uo.unlocked_method_dont_let_locked_methods_mutate('asdf')}
    end
  end

  def test_unlocked_methods_can_call_locked_methods
    obj = @@klass.new_locked_ldp_object(title: 'A Work')

    obj.unlock_and_fetch_ldp_object do |uo|
      assert_equal "Title is: A Work", uo.safe_locked_method
    end
  end

  def test_unlocked_methods_can_mutate
    obj = @@klass.new_locked_ldp_object(title: 'A Work')

    obj.unlock_and_fetch_ldp_object do |unlocked_object|
      assert_equal 'A Work', unlocked_object.title
      unlocked_object.title = 'A New Title'
    end

    assert_equal 'A New Title', obj.title

    obj.unlock_and_fetch_ldp_object do |unlocked_object|
      unlocked_object.unlocked_method_can_mutate('Another New Title')
    end

    assert_equal 'Another New Title', obj.title
  end

  def test_object_inspecting
    obj = @@klass.new_locked_ldp_object(title: 'A Work')
    assert_equal "#<AnonymousClass id: nil, title: \"A Work\", member_of_paths: []>", obj.inspect
  end

  def test_inheritance_of_attributes
    subclass = Class.new(@@klass) do
      has_attribute :subject, ::RDF::Vocab::DC.subject, solrize_for: :search
    end

    assert_equal subclass.attribute_names.sort, [:id, :member_of_paths, :subject, :title]
    # ensure mutating subclass attribute lists isn't trickling back to the superclass
    assert_equal @@klass.attribute_names.sort, [:id, :member_of_paths, :title]
  end

  def test_attributes
    obj = @@klass.new_locked_ldp_object(title: 'A Work')
    assert obj.attributes.key? 'title'
    assert_equal 'A Work', obj.attributes['title']
    assert obj.attributes.key? 'id'

    assert obj.display_attributes.key? 'title'
    assert_not obj.display_attributes.key? 'id'
    assert_equal 'A Work', obj.display_attributes['title']
  end

  def test_activemodel_integration
    obj = @@klass.new_locked_ldp_object

    assert_instance_of ActiveModel::Errors, obj.errors
    assert_not_predicate obj.errors, :any?
    assert_not_predicate obj, :persisted?
    assert_not_predicate obj, :changed?
    assert_predicate obj, :valid?

    obj.unlock_and_fetch_ldp_object {|uo| uo.title = 'Title'}

    assert_predicate obj, :changed?

    # TODO validation and persistence
  end

  # search

end
