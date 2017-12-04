class SearchTest < ActiveSupport::TestCase

  @@klass = Class.new(JupiterCore::LockedLdpObject) do
    ldp_object_includes Hydra::Works::WorkBehavior
    has_attribute :title, ::RDF::Vocab::DC.title, solrize_for: [:search, :facet]
    has_attribute :creator, ::RDF::Vocab::DC.creator, solrize_for: [:search, :facet]
    has_multival_attribute :member_of_paths, ::VOCABULARY[:ual].path, type: :path, solrize_for: :pathing

    additional_search_index :my_solr_doc_attr, solrize_for: :search, as: -> { 'a_test_value' }

    def locked_method_shouldnt_mutate(attempted_title)
      self.title = attempted_title
    end

    def safe_locked_method
      "Title is: #{title}"
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

  test 'basic search functionality' do
    first_title = generate_random_string
    second_title = generate_random_string
    creator = generate_random_string
    creator2 = generate_random_string

    obj = @@klass.new_locked_ldp_object(title: first_title, creator: creator, visibility: 'public',
                                        owner: users(:regular_user).id)
    another_obj = @@klass.new_locked_ldp_object(title: second_title, creator: creator2, visibility: 'public',
                                                owner: users(:regular_user).id)
    a_private_object = @@klass.new_locked_ldp_object(title: generate_random_string, creator: generate_random_string,
                                                     visibility: 'private', owner: users(:regular_user).id)

    obj.unlock_and_fetch_ldp_object(&:save!)
    another_obj.unlock_and_fetch_ldp_object(&:save!)
    a_private_object.unlock_and_fetch_ldp_object(&:save!)

    search_results = JupiterCore::Search.faceted_search(models: @@klass, q: '')

    assert search_results.count == 2

    search_results.each do |res|
      assert_includes [obj, another_obj].map(&:id), res.id
      assert_not res.id == a_private_object.id
    end

    search_results.each_facet_with_results do |facet|
      assert_includes ['Title', 'Creator', 'Visibility'], facet.category_name
      if facet.category_name == 'Title'
        assert facet.values.keys.count == 2
        assert facet.values.key?(first_title)
        assert facet.values.key?(second_title)
        [first_title, second_title].each do |title|
          assert facet.values[title] == 1
        end
      elsif facet.category_name == 'Creator'
        assert facet.values.keys.count == 2
        assert facet.values.key?(creator)
        assert facet.values[creator] == 1
      elsif facet.category_name == 'Visibility'
        assert facet.values.keys.count == 1
        assert facet.values.key?('public')
        assert facet.values['public'] == 2
      end
    end

    search_results = JupiterCore::Search.faceted_search(models: @@klass, q: creator2)

    assert search_results.count == 1
    assert_equal search_results.first.id, another_obj.id
  end

end
