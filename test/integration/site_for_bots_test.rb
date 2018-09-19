require 'test_helper'

class SiteForBotsTest < ActionDispatch::IntegrationTest

  def before_all
    super

    # TODO: setup proper fixtures for LockedLdpObjects

    # A community with two collections
    @community1 = Community
                  .new_locked_ldp_object(title: 'Two collection community', owner: 1)
                  .unlock_and_fetch_ldp_object(&:save!)
    @collection1 = Collection
                   .new_locked_ldp_object(community_id: @community1.id,
                                          title: 'Nice collection', owner: 1)
                   .unlock_and_fetch_ldp_object(&:save!)
    @collection2 = Collection
                   .new_locked_ldp_object(community_id: @community1.id,
                                          title: 'Another collection', owner: 1)
                   .unlock_and_fetch_ldp_object(&:save!)
    @item = Item.new_locked_ldp_object.unlock_and_fetch_ldp_object do |uo|
      uo.title = 'Fantastic item'
      uo.owner = 1
      uo.creators = ['Joe Blow', 'Smokey Chantilly-Tiffany', 'Céline Marie Claudette Dion']
      uo.visibility = JupiterCore::VISIBILITY_PUBLIC
      uo.created = '1999-09-09'
      uo.languages = [CONTROLLED_VOCABULARIES[:language].english]
      uo.license = CONTROLLED_VOCABULARIES[:license].attribution_4_0_international
      uo.item_type = CONTROLLED_VOCABULARIES[:item_type].article
      uo.publication_status = [CONTROLLED_VOCABULARIES[:publication_status].draft,
                               CONTROLLED_VOCABULARIES[:publication_status].submitted]
      uo.subject = ['Items']
      uo.add_to_path(@community1.id, @collection1.id)
      uo.add_to_path(@community1.id, @collection2.id)
      uo.save!
    end
    Sidekiq::Testing.inline! do
      # Attach a file to the item so that it has download to check for
      File.open(file_fixture('pdf-sample.pdf'), 'r') do |file|
        @item.add_and_ingest_files([file])
      end
    end
    @thesis = Thesis.new_locked_ldp_object.unlock_and_fetch_ldp_object do |uo|
      uo.title = 'Fantasitc thesis'
      uo.owner = 1
      uo.dissertant = 'Joe Blow'
      uo.visibility = JupiterCore::VISIBILITY_PUBLIC
      uo.graduation_date = '2017-03-31'
      uo.add_to_path(@community1.id, @collection1.id)
      uo.save!
    end
    Sidekiq::Testing.inline! do
      # Attach a file to the item so that it has download check for
      File.open(file_fixture('pdf-sample.pdf'), 'r') do |file|
        @thesis.add_and_ingest_files([file])
      end
    end
    @public_paths = [root_path, item_path(@item), communities_path, community_path(@community1),
                     community_collection_path(@community1, @collection1), search_path]
  end

  test 'unique title and description for each page' do
    collect_titles = [], collect_descriptions = []
    @public_paths.each do |route|
      get route
      assert_select 'title', count: 1 do |title|
        collect_titles << title
      end
      # search_path is noindex so description shouldn't matter
      next if search_path == route
      assert_select "meta[name='description']", count: 1 do |description|
        collect_descriptions << description
      end
    end
    assert_equal collect_titles, collect_titles.uniq, 'should have unique titles'
    assert_equal collect_titles, collect_titles.uniq, 'should have unique descriptions'
  end

  test 'search results should be noindex' do
    get search_path
    assert_select "meta[name='robots'][content='noindex']"

    get search_path(tab: 'item')
    assert_select "meta[name='robots'][content='noindex']"

    get search_path(tab: 'collection')
    assert_select "meta[name='robots'][content='noindex']"

    get search_path(tab: 'community')
    assert_select "meta[name='robots'][content='noindex']"
  end

  test 'nofollow for download links' do
    # on search page (for item and thesis)
    get search_path
    assert_select "a[rel='nofollow']", text: I18n.t('download'), count: 2

    # on show page (for item and thesis)
    get item_path @item
    assert_select "a[rel='nofollow']", text: I18n.t('download'), count: 1

    get item_path @thesis
    assert_select "a[rel='nofollow']", text: I18n.t('download'), count: 1
  end

  test 'nofollow for facets' do
    get search_path
    assert_select '.filter-list' do
      assert_select "a[rel='nofollow']"
    end
  end

  test 'nofollow for item metadata links to search' do
    get item_path @item
    assert_select "a[rel='nofollow']", text: @item.creators.first
    assert_select "a[rel='nofollow']", text: @item.creation_date
    assert_select "a[rel='nofollow']", text: 'English'
    assert_select "a[rel='nofollow']", text: 'Article (Draft / Submitted)'
    assert_select "a[rel='nofollow']", text: @item.subject.first
  end

  test 'structured data for google scholar' do
    # TODO: can be a lot more complicated see https://scholar.google.com/intl/en/scholar/inclusion.html#indexing
    get item_path @thesis
    assert_select "meta[name='citation_title'][content='#{@thesis.title}']"
    assert_select "meta[name='citation_author'][content='#{@thesis.dissertant}']"
    assert_select "meta[name='citation_publication_date'][content='#{@thesis.creation_date}']"
    assert_select format("meta[name='citation_pdf_url'][content='%s']",
                         file_view_item_url(
                           id: @thesis.id,
                           file_set_id: @thesis.files.first.fileset_uuid,
                           file_name: @thesis.files.first.filename.to_s
                         ))
    assert_select "meta[name='dc.identifier'][content='#{@item.doi}']"
    assert_select "meta[name='citation_doi'][content='#{@item.doi}']"

    get item_path @item
    assert_select "meta[name='citation_title'][content='#{@item.title}']"
    @item.creators.each do |author|
      assert_select "meta[name='citation_author'][content='#{author}']"
    end
    assert_select "meta[name='citation_publication_date'][content='#{@item.creation_date}']"
    assert_select format("meta[name='citation_pdf_url'][content='%s']",
                         file_view_item_url(
                           id: @item.id,
                           file_set_id: @item.files.first.fileset_uuid,
                           file_name: @item.files.first.filename
                         ))
    assert_select "meta[name='dc.identifier'][content='#{@item.doi}']"
    assert_select "meta[name='citation_doi'][content='#{@item.doi}']"
  end

  test 'alt attributes on images' do
    @public_paths.each do |route|
      get route
      assert_select 'img' do |images|
        assert_select '[alt]', count: images.count
      end
    end
  end

  test 'viewport used' do
    @public_paths.each do |route|
      get route
      assert_select "meta[name='viewport']", count: 1
    end
  end

  test 'search page with query params should link to canonical version of search' do
    # canonical should appear for the default
    get search_path
    assert_select 'link[rel="canonical"]:match("href", ?)', search_url

    # canonical should appear for the item tab
    get search_path(search: 'random', tab: 'item')
    assert_select 'link[rel="canonical"]:match("href", ?)', search_url

    # canonical should appear for the collection tab
    get search_path(tab: 'collection')
    assert_select 'link[rel="canonical"]:match("href", ?)', search_url

    # canonical should appear for the community tab
    get search_path(tab: 'community')
    assert_select 'link[rel="canonical"]:match("href", ?)', search_url
  end

end
