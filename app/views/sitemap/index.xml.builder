xml.instruct! :xml, version: '1.0'
xml.sitemapindex xmlns: 'http://www.sitemaps.org/schemas/sitemap/0.9' do
  [:items, :theses, :collections, :communities].each do |category|
    xml.sitemap do
      xml.loc url_for(action: category, controller: 'sitemap', only_path: false)
    end
  end
end
