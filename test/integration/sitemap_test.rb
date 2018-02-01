require 'test_helper'

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
                  file = File.open(file_fixture('image-sample.jpeg'), 'r')
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
    should 'be valid sitemapindex xml' do
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
  end

  context 'items sitemap' do
    should 'be valid sitemap xml' do
      get items_sitemap_url

      schema = Nokogiri::XML::Schema(File.open(file_fixture('sitemap.xsd')))
      document = Nokogiri::XML(@response.body)
      assert_empty schema.validate(document)

      assert_select 'url' do
        assert_select 'loc'
        assert_select 'lastmod'
        assert_select 'changefreq'
        assert_select 'priority'
        assert_select 'rs|md[type=?]', 'text/html'
      end

      # show public item attributes
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

      # not show private items
      assert_select 'url', count: 2
      assert_select 'loc', { count: 0, text: item_url(@private_item) }, 'private items should not appear in the sitemap'
    end
  end

  context 'collections sitemap' do
    should 'be valid sitemap xml' do
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
  end

  context 'communities sitemap' do
    should 'be valid sitemap xml' do
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

end
