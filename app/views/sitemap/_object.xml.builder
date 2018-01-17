objects.each do |object|
  xml.url do
    xml.loc item_url(object)
    xml.changefreq 'weekly'
    xml.priority   1
    xml.lastmod object.updated_at
    xml.rs :md, type: 'text/html'
    object.file_sets.each do |file_set|
      xml << "\t#{file_set.sitemap_link}\n"
    end
  end
end
