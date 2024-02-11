require 'test_helper'

class SearchTest < ActiveSupport::TestCase

  test 'default behaviour within a facet is OR and between facets is AND' do
    item1 = items(:item_fancy)
    item2 = items(:item_practical)

    [item1, item2].each(&:update_solr)
    results = JupiterCore::Search.faceted_search(models: [Item],
                                                 facets: {
                                                   all_subjects_sim: ['Fancy things',
                                                                      'Practical things'],
                                                   all_contributors_sim: ['Joe Blow']
                                                 })

    assert_includes results, item1
    assert_includes results, item2

    assert_includes results.criteria[:fq],
                    'all_subjects_sim:("Fancy things" OR "Practical things") AND all_contributors_sim:("Joe Blow")'
  end

end
