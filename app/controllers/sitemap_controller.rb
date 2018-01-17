class SitemapController < ApplicationController

  skip_after_action :verify_authorized

  def index; end

  def communities
    @communities = Community.all
    raise 'sitemap should contain less than 50,000 targets' if @communities.count > 50_000
  end

  def collections
    @collections = Collection.all
    raise 'sitemap should contain less than 50,000 targets' if @collections.count > 50_000
  end

  def items
    @items = Item.public
    raise 'sitemap should contain less than 50,000 targets' if @items.count > 50_000
  end

  def theses
    @theses = Thesis.all
    raise 'sitemap should contain less than 50,000 targets' if @theses.count > 50_000
  end

end
