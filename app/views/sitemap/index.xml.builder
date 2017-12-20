xml.instruct! :xml, version: '1.0'
cache 'sitemap', expires_in: 24.hours do
  xml.urlset(xmlns: 'http://www.sitemaps.org/schemas/sitemap/0.9') do
    xml.url do
      xml.loc        root_url
      xml.lastmod    Time.current.utc.iso8601
      xml.changefreq 'weekly'
      xml.priority   1
    end

    @communities.each do |community|
      xml.url do
        xml.loc community_url(community)
        xml.changefreq 'weekly'
        xml.priority   1
        xml.lastmod Time.current.utc.iso8601 # TODO
      end
    end

    @collections.each do |collection|
      xml.url do
        xml.loc community_collection_url(collection.community, collection)
        xml.changefreq 'weekly'
        xml.priority   1
        xml.lastmod Time.current.utc.iso8601 # TODO
      end
    end

    @items.each do |item|
      xml.url do
        xml.loc item_url(item)
        xml.changefreq 'weekly'
        xml.priority   1
        xml.lastmod Time.current.utc.iso8601 # TODO
      end
    end
  end
end
