xml.instruct! :xml, version: '1.0'
cache 'sitemap', expires_in: 24.hours do
  xml.urlset(xmlns: 'http://www.sitemaps.org/schemas/sitemap/0.9') do
    xml.url do
      xml.loc        root_url
      xml.lastmod    Time.current.iso8601
      xml.changefreq 'weekly'
      xml.priority   1
    end

    objects.each do |object|
      xml.url do
        xml.loc item_url(object)
        xml.lastmod object.updated_at
        xml.changefreq 'weekly'
        xml.priority   1
      end
    end
  end
end
