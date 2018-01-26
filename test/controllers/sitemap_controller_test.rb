require 'test_helper'
require 'open-uri'

class SitemapTest < ActionDispatch::IntegrationTest

  def before_all
    super
    @community = Community.new_locked_ldp_object(title: 'Fancy Community', owner: 1)
                          .unlock_and_fetch_ldp_object(&:save!)
    @collection = Collection.new_locked_ldp_object(community_id: @community.id,
                                                   title: 'Fancy Collection', owner: 1)
                            .unlock_and_fetch_ldp_object(&:save!)
    @item = Item.new_locked_ldp_object(visibility: JupiterCore::VISIBILITY_PUBLIC,
                                       owner: 1, title: 'Fancy Item',
                                       creators: ['Joe Blow'],
                                       created: '1938-01-02',
                                       languages: [CONTROLLED_VOCABULARIES[:language].english],
                                       item_type: CONTROLLED_VOCABULARIES[:item_type].article,
                                       publication_status: [CONTROLLED_VOCABULARIES[:publication_status].published],
                                       license: CONTROLLED_VOCABULARIES[:license].attribution_4_0_international,
                                       subject: ['Items'])
                .unlock_and_fetch_ldp_object do |uo|
                  uo.add_to_path(@community.id, @collection.id)
                  uo.save!
                  # Attach a file to the item so that it has attributes to check for
                  file = File.open(Rails.root + 'app/assets/images/mc_360.png', 'r')
                  uo.add_files([file])
                  file.close
                end
    @thesis = Thesis.new_locked_ldp_object(visibility: JupiterCore::VISIBILITY_PUBLIC,
                                           owner: 1, title: 'Fancy Item',
                                           dissertant: 'Joe Blow',
                                           language: CONTROLLED_VOCABULARIES[:language].english,
                                           graduation_date: 'Fall 2017')
                    .unlock_and_fetch_ldp_object do |uo|
                      uo.add_to_path(@community.id, @collection.id)
                      uo.save!
                    end
    # 1 more item. this is private
    @private_item = Item.new_locked_ldp_object(visibility: JupiterCore::VISIBILITY_PRIVATE,
                                               owner: 1, title: 'Fancy Private Item',
                                               creators: ['Joe Blow'],
                                               created: '1983-11-11',
                                               languages: [CONTROLLED_VOCABULARIES[:language].english],
                                               item_type: CONTROLLED_VOCABULARIES[:item_type].article,
                                               publication_status:
                                               [CONTROLLED_VOCABULARIES[:publication_status].published],
                                               license: CONTROLLED_VOCABULARIES[:license].attribution_4_0_international,
                                               subject: ['Items'])
                        .unlock_and_fetch_ldp_object do |uo|
                          uo.add_to_path(@community.id, @collection.id)
                          uo.save!
                        end
  end

  context 'sitemap index' do
    setup do
      get sitemapindex_url
    end
    should 'be valid sitemapindex xml' do
      schema = Nokogiri::XML::Schema(File.open(File.join(File.dirname(__FILE__), 'siteindex.xsd')))
      document = Nokogiri::XML(@response.body)
      assert_empty schema.validate(document)
    end
    should 'show sitemap for each of communities, collections, items and thesis' do
      assert_select 'sitemap', 4
      assert_select 'loc', /sitemap-items.xml/
      assert_select 'loc', /sitemap-theses.xml/
      assert_select 'loc', /sitemap-communities.xml/
      assert_select 'loc', /sitemap-collections.xml/
    end
  end

  context 'items sitemap' do
    setup do
      get items_sitemap_url
    end
    should 'be valid sitemap xml' do
      schema = Nokogiri::XML::Schema(File.open(File.join(File.dirname(__FILE__), 'sitemap.xsd')))
      document = Nokogiri::XML(@response.body)
      assert_empty schema.validate(document)
    end
    should 'show url, last modified date, change frequency, priority and type' do
      assert_select 'url' do
        assert_select 'loc'
        assert_select 'lastmod'
        assert_select 'changefreq'
        assert_select 'priority'
        assert_select 'rs|md[type=?]', 'text/html'
      end
    end
    should 'show public item attributes' do
      assert_select 'loc', item_url(@item)
      assert_select 'lastmod', @item.updated_at.to_s
      @item.file_sets.first.unlock_and_fetch_ldp_object do |uo|
        assert_select 'rs|ln[href=?]', url_for(controller: :file_sets,
                                               action: :download,
                                               id: uo.id,
                                               file_name: uo.contained_filename,
                                               only_path: true)
        assert_select 'rs|ln[hash=?]',
                      "#{uo.original_file.checksum.algorithm.downcase}:#{uo.original_file.checksum.value}"
        assert_select 'rs|ln[length=?]', uo.original_file.size.to_s
        assert_select 'rs|ln[type=?]', uo.original_file.mime_type.to_s
      end
    end

    should 'not show private items' do
      assert_select 'url', count: 2
      assert_select 'loc', { count: 0, text: item_url(@private_item) }, 'private items shant appear in the sitemap'
    end
  end

  context 'collections sitemap' do
    setup do
      get collections_sitemap_url
    end
    should 'be valid sitemap xml' do
      get collections_sitemap_url
      schema = Nokogiri::XML::Schema(File.open(File.join(File.dirname(__FILE__), 'sitemap.xsd')))
      document = Nokogiri::XML(@response.body)
      assert_empty schema.validate(document)
    end
    should 'show url, last modified date, change frequency and priority' do
      assert_select 'url' do
        assert_select 'loc'
        assert_select 'lastmod'
        assert_select 'changefreq'
        assert_select 'priority'
      end
    end
    should 'show location and last modified' do
      assert_select 'loc', community_collection_url(@collection.community, @collection)
      assert_select 'lastmod', @collection.updated_at.to_s\
    end
  end

  context 'communities sitemap' do
    setup do
      get communities_sitemap_url
    end
    should 'be valid sitemap xml' do
      get communities_sitemap_url
      schema = Nokogiri::XML::Schema(File.open(File.join(File.dirname(__FILE__), 'sitemap.xsd')))
      document = Nokogiri::XML(@response.body)
      assert_empty schema.validate(document)
    end
    should 'show url, last modified date, change frequency and priority' do
      assert_select 'url' do
        assert_select 'loc'
        assert_select 'lastmod'
        assert_select 'changefreq'
        assert_select 'priority'
      end
    end
    should 'show location and last modified' do
      assert_select 'loc', community_url(@community)
      assert_select 'lastmod', @community.updated_at.to_s\
    end
  end

end
