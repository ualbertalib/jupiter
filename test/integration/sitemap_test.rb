require 'test_helper'

class SitemapTest < ActionDispatch::IntegrationTest

  setup do
    @community = communities(:books)
    @collection = collections(:fantasy_books)
    @item = items(:fancy)

    # Attach a file to the item so that it has attributes to check for
    File.open(file_fixture('image-sample.jpeg'), 'r') do |file|
      # Bit of a hack to fake a file name with characters that require escaping ...
      def file.original_filename
        "ü&<>'\".jpeg"
      end
      @item.add_and_ingest_files([file])
    end

    @thesis = thesis(:nice)
    @private_item = items(:private_item)
  end

  test 'sitemap index should be valid sitemapindex xml' do
    get sitemapindex_url

    schema = Nokogiri::XML::Schema(File.open(file_fixture('siteindex.xsd')))
    document = Nokogiri::XML(@response.body)
    assert_empty schema.validate(document)

    assert_select 'sitemap', 4
    assert_select 'loc', /sitemap-items.xml/
    assert_select 'loc', /sitemap-theses.xml/
    assert_select 'loc', /sitemap-communities.xml/
    assert_select 'loc', /sitemap-collections.xml/
  end

  test 'items sitemap should be valid sitemap xml' do
    get items_sitemap_url

    schema = Nokogiri::XML::Schema(File.open(file_fixture('sitemap.xsd')))
    document = Nokogiri::XML(@response.body)
    assert_empty schema.validate(document)

    assert_select 'url' do
      assert_select 'loc'
      assert_select 'lastmod'
      assert_select 'changefreq'
      assert_select 'priority'
    end

    # show public item attributes
    assert_select 'loc', item_url(@item)
    assert_select 'lastmod', @item.updated_at.iso8601
    # not show private items
    assert_select 'url', count: 3
    assert_select 'loc', { count: 0, text: item_url(@private_item) }, 'private items should not appear in the sitemap'
  end

  test 'collections sitemap should be valid sitemap xml' do
    get collections_sitemap_url

    schema = Nokogiri::XML::Schema(File.open(file_fixture('sitemap.xsd')))
    document = Nokogiri::XML(@response.body)
    assert_empty schema.validate(document)

    assert_select 'url' do
      assert_select 'loc'
      assert_select 'lastmod'
      assert_select 'changefreq'
      assert_select 'priority'
    end

    assert_select 'loc', community_collection_url(@collection.community, @collection)

    # TODO: Need to figure this assert out, not consistent and breaking tests periodically (especially on CI)
    # assert_select 'lastmod', @collection.updated_at.utc.iso8601
  end

  test 'communities sitemap should be valid sitemap xml' do
    get communities_sitemap_url

    schema = Nokogiri::XML::Schema(File.open(file_fixture('sitemap.xsd')))
    document = Nokogiri::XML(@response.body)
    assert_empty schema.validate(document)

    assert_select 'url' do
      assert_select 'loc'
      assert_select 'lastmod'
      assert_select 'changefreq'
      assert_select 'priority'
    end

    assert_select 'loc', community_url(@community)

    # TODO: Need to figure this assert out, not consistent and breaking tests periodically (especially on CI)
    # assert_select 'lastmod', @community.updated_at.utc.iso8601
  end

end
