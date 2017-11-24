require 'test_helper'

class LockedLdpObjectTest < ActiveSupport::TestCase

  @@klass = Class.new(JupiterCore::LockedLdpObject) do
    ldp_object_includes Hydra::Works::WorkBehavior
    has_attribute :title, ::RDF::Vocab::DC.title, solrize_for: [:search, :facet]
    has_attribute :creator, ::RDF::Vocab::DC.creator, solrize_for: [:search, :facet]
    has_multival_attribute :member_of_paths, ::VOCABULARY[:ualib].path, solrize_for: :pathing

    additional_search_index :my_solr_doc_attr, solrize_for: :search, as: -> { title&.upcase }

    def locked_method_shouldnt_mutate(attempted_title)
      self.title = attempted_title
    end

    def safe_locked_method
      "Title is: #{title}"
    end

    unlocked do
      before_validation :before_validation_method
      after_validation :after_validation_method

      def before_validation_method; end

      def after_validation_method; end

      def unlocked_method_can_mutate(attempted_title)
        self.title = attempted_title
      end

      def unlocked_method_dont_let_locked_methods_mutate(attempted_title)
        locked_method_shouldnt_mutate(attempted_title)
      end
    end
  end

  # this fails if the call to super doesn't happen in JupiterCore::LockedLdpObject.inherited
  test 'inheritance is being tracked properly' do
    assert_includes JupiterCore::LockedLdpObject.descendants, @@klass
  end

  test 'the list of safe attributes never includes the id' do
    JupiterCore::LockedLdpObject.descendants.each do |klass|
      assert_not_includes klass.safe_attributes, :id
    end
  end

  test 'the shared indexer is being used' do
    assert_equal @@klass.send(:derived_af_class).indexer, JupiterCore::Indexer
  end

  test 'derived AF objects are including the proper modules' do
    assert @@klass.send(:derived_af_class).include? Hydra::Works::WorkBehavior
  end

  test 'attribute definitions are working' do
    assert_equal [:creator, :id, :member_of_paths, :owner, :record_created_at, :title, :visibility],
                 @@klass.attribute_names.sort
  end

  test 'attribute metadata is being tracked properly' do
    title_metadata = @@klass.attribute_metadata(:title)

    assert_instance_of Hash, title_metadata
    assert_equal ::RDF::Vocab::DC.title, title_metadata[:predicate]
    assert_equal :string, title_metadata[:type]
    assert_not title_metadata[:multiple]
    assert_equal [:search, :facet], title_metadata[:solrize_for]
    assert_equal ['title_tesim', 'title_sim'], title_metadata[:solr_names]

    assert @@klass.attribute_metadata(:member_of_paths)[:multiple]

    title = generate_random_string
    obj = @@klass.new_locked_ldp_object(title: title)

    assert_equal obj.search_term_for(:title), %Q(title_tesim:"#{title}")
  end

  test 'solr calculated attributes are working properly' do
    title = generate_random_string
    obj = @@klass.new_locked_ldp_object(title: title)

    obj.unlock_and_fetch_ldp_object do |uo|
      solr_doc = uo.to_solr

      assert solr_doc.key? 'my_solr_doc_attr_tesim'
      assert_includes solr_doc['my_solr_doc_attr_tesim'], title.upcase
    end
  end

  test 'reverse solr name lookup is working properly' do
    assert_equal :title, @@klass.solr_name_to_attribute_name('title_tesim')
    assert_equal :member_of_paths, @@klass.solr_name_to_attribute_name('member_of_paths_dpsim')
  end

  test 'the default constructor is private' do
    assert_raises ::NoMethodError do
      @@klass.new
    end
  end

  test 'locked objects are not mutatable' do
    original_title = generate_random_string
    obj = @@klass.new_locked_ldp_object(title: original_title)

    assert_equal original_title, obj.title

    assert_raises JupiterCore::LockedInstanceError do
      obj.title = generate_random_string
    end

    assert_raises JupiterCore::LockedInstanceError do
      obj.locked_method_shouldnt_mutate(generate_random_string)
    end

    assert_raises JupiterCore::LockedInstanceError do
      obj.unlocked_method_can_mutate(generate_random_string)
    end

    assert_raises JupiterCore::LockedInstanceError do
      obj.unlock_and_fetch_ldp_object { |uo| uo.unlocked_method_dont_let_locked_methods_mutate(generate_random_string) }
    end

    assert_equal original_title, obj.title
  end

  test 'unlocked methods can call locked objects' do
    title = generate_random_string
    obj = @@klass.new_locked_ldp_object(title: title)

    obj.unlock_and_fetch_ldp_object do |uo|
      assert_equal "Title is: #{title}", uo.safe_locked_method
    end
  end

  test 'solr_name_for' do
    assert_equal @@klass.solr_name_for(:title, role: :search), 'title_tesim'
  end

  test 'unlocked methods can perform mutation' do
    orig_title = generate_random_string
    obj = @@klass.new_locked_ldp_object(title: orig_title)

    new_title = generate_random_string

    obj.unlock_and_fetch_ldp_object do |unlocked_object|
      assert_equal orig_title, unlocked_object.title
      unlocked_object.title = new_title
    end

    assert_equal new_title, obj.title

    another_new_title = generate_random_string

    obj.unlock_and_fetch_ldp_object do |unlocked_object|
      unlocked_object.unlocked_method_can_mutate(another_new_title)
    end

    assert_equal another_new_title, obj.title
  end

  test '#inspect works as expected' do
    title = generate_random_string
    obj = @@klass.new_locked_ldp_object(title: title)
    assert_equal "#<AnonymousClass id: nil, visibility: nil, owner: nil, record_created_at: nil, title: \"#{title}\","\
                 ' creator: nil, member_of_paths: []>', obj.inspect
  end

  test 'attribute inheritance is working' do
    subclass = Class.new(@@klass) do
      has_attribute :subject, ::RDF::Vocab::DC.subject, solrize_for: :search
    end

    assert_equal [:creator, :id, :member_of_paths, :owner, :record_created_at, :subject, :title, :visibility],
                 subclass.attribute_names.sort
    # ensure mutating subclass attribute lists isn't trickling back to the superclass
    assert_equal [:creator, :id, :member_of_paths, :owner, :record_created_at, :title, :visibility],
                 @@klass.attribute_names.sort
  end

  test 'attributes are declaring properly' do
    title = generate_random_string
    obj = @@klass.new_locked_ldp_object(title: title)
    assert obj.attributes.key? 'title'
    assert_equal title, obj.attributes['title']
    assert obj.attributes.key? 'id'

    assert obj.display_attributes.key? 'title'
    assert_not obj.display_attributes.key? 'id'
    assert_equal title, obj.display_attributes['title']
  end

  test 'active model integration is working' do
    obj = @@klass.new_locked_ldp_object

    assert_instance_of ActiveModel::Errors, obj.errors
    assert_not_predicate obj.errors, :any?
    assert_not_predicate obj, :persisted?
    assert_not_predicate obj, :changed?
    assert_not_predicate obj, :valid?

    obj.unlock_and_fetch_ldp_object do |uo|
      uo.title = 'Title'
      uo.visibility = JupiterCore::VISIBILITY_PUBLIC
      uo.owner = users(:regular_user).id
    end

    assert_predicate obj, :changed?
    assert_predicate obj, :valid?
  end

  test 'solr integration is working' do
    assert @@klass.all.count == 0

    creator = generate_random_string
    first_title = generate_random_string

    obj = @@klass.new_locked_ldp_object(title: first_title, creator: creator, owner: users(:regular_user).id,
                                        visibility: 'public')

    assert obj.record_created_at.nil?

    freeze_time do
      obj.unlock_and_fetch_ldp_object(&:save!)
      assert obj.id.present?
      assert obj.record_created_at.present?
      assert_equal obj.record_created_at, Time.current
    end

    assert @@klass.all.count == 1

    assert_equal first_title, @@klass.all.first.title

    second_title = generate_random_string

    another_obj = @@klass.new_locked_ldp_object(title: second_title, creator: creator, owner: users(:regular_user).id,
                                                visibility: 'public')
    another_obj.unlock_and_fetch_ldp_object(&:save!)

    assert @@klass.all.count == 2

    assert @@klass.where(title: second_title).present?
    assert @@klass.where(title: second_title).first.id == another_obj.id

    assert_raises JupiterCore::ObjectNotFound do
      @@klass.find(generate_random_string)
    end

    assert_nil @@klass.find_by(generate_random_string)

    assert @@klass.find(obj.id).present?

    assert_equal @@klass.first.id, obj.id
    assert_equal @@klass.last.id, another_obj.id

    assert_equal @@klass.where(id: obj.id).first.id, obj.id
  end

  # TODO: maybe "upstream" deserves its own section in our test suite

  #  (╯°□°）╯︵ ┻━┻)
  test 'Validation callbacks actually, yknow, run. Seriously. I have to test for this.' do
    obj = @@klass.new_locked_ldp_object(title: generate_random_string)

    obj.unlock_and_fetch_ldp_object do |uo|
      before_mock = MiniTest::Mock.new
      before_mock.expect :call, true

      after_mock = MiniTest::Mock.new
      after_mock.expect :call, true

      uo.stub :before_validation_method, before_mock do
        uo.stub :after_validation_method, after_mock do
          obj.valid?
        end
      end
      assert_mock before_mock
      assert_mock after_mock
    end
  end

  # You might ask yourself, "Should we be writing tests to validate basic functionality of upstream dependencies?"
  #
  # No.
  # We should not _have_ to.
  #
  # (ﾉ °益°)ﾉ 彡 ┻━┻
  test 'we are using a branch of ActiveFedora and Solrizer where index type works' do
    klass = Class.new(ActiveFedora::Base) do
      property :foo, predicate: ::RDF::Vocab::DC.created, multiple: false do |index|
        index.type :date
        index.as :stored_sortable
      end
    end

    # This should work even with vanilla AF/Solrizer
    instance = klass.new
    instance.foo = Time.current

    assert instance.to_solr.key? 'foo_dtsi'
    refute instance.to_solr.key? 'foo_ssi'

    # This will be broken on vanilla AF/Solrizer. Assigning a string will reveal that the index.type is non-functional
    # and ignored. foo will be solrized as a stored sortable string, foo_ssi, and not a date.
    instance.foo = Time.current

    assert instance.to_solr.key? 'foo_dtsi'
    refute instance.to_solr.key? 'foo_ssi'
  end

  # This is definitely up there in terms of the craziest things I've ever had to write a test for.
  test 'times dont get warped into the past when the object is saved' do
    klass = Class.new(JupiterCore::LockedLdpObject) do
      has_attribute :embargo_date, ::RDF::Vocab::DC.modified, type: :date, solrize_for: [:sort]
    end
    instance = klass.new_locked_ldp_object(owner: 1, visibility: JupiterCore::VISIBILITY_PUBLIC)

    instance.unlock_and_fetch_ldp_object do |unlocked_instance|
      unlocked_instance.embargo_date = Time.current + 200.years
    end

    # So far so good. Things should be what we set them to be.
    assert_equal instance.embargo_date.year, Time.current.year + 200

    # Here's where things get stupid
    instance.unlock_and_fetch_ldp_object(&:save)

    # ActiveFedora / RDF completely screw up the serialization of Time objects, and end up losing the date aspects
    # of the time, causing our embargo date to silently become today when saved.
    # This test will fail if we haven't succesfully corrected for this in JupiterCore::LockedLdpObject
    assert instance.embargo_date.year != Time.current.year
  end

  test 'hoisted activefedora associations' do
    klass = Class.new(JupiterCore::LockedLdpObject) do
      ldp_object_includes Hydra::Works::FileSetBehavior
      belongs_to :item, using_existing_association: :member_of_collections
    end
    instance = klass.new_locked_ldp_object(owner: 1, visibility: JupiterCore::VISIBILITY_PUBLIC)

    assert instance.respond_to?(:item)
    assert_nil instance.item, nil
    assert_equal instance.inspect, '#<AnonymousClass id: nil, visibility: "public", owner: 1,'\
                                   ' record_created_at: nil, item: nil>'
    instance.unlock_and_fetch_ldp_object(&:save)

    instance2 = klass.new_locked_ldp_object(owner: 1,
                                            visibility: JupiterCore::VISIBILITY_PUBLIC, item: instance)

    instance2.unlock_and_fetch_ldp_object(&:save)
    assert_equal instance2.item, instance.id

    fetched_object = klass.where(item: instance.id).first

    assert fetched_object.present?
    assert_equal fetched_object.id, instance2.id

    another_klass = Class.new(JupiterCore::LockedLdpObject) do
      ldp_object_includes Hydra::Works::FileSetBehavior
      has_many :items, using_existing_association: :member_of_collections
    end

    another_instance = another_klass.new_locked_ldp_object(owner: 1, visibility: JupiterCore::VISIBILITY_PUBLIC,
                                                           items: [instance])
    assert another_instance.items.is_a?(Array)
    assert_equal another_instance.items.first, instance.id

    assert_raises JupiterCore::LockedInstanceError do
      another_instance.items = [instance, instance2]
    end

    another_instance.unlock_and_fetch_ldp_object do |uo|
      uo.items = [instance, instance2]
    end

    assert_equal another_instance.items.first, instance.id
    assert_equal another_instance.items.last, instance2.id
  end

end
