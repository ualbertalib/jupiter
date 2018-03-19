class SitemapController < ApplicationController

  skip_after_action :verify_authorized

  def index; end

  def communities
    @communities = Community.all
    Rollbar.warning 'communities sitemap should contain less than 50,000 targets' if @communities.total_count > 50_000
  end

  def collections
    @collections = Collection.all
    Rollbar.warning 'collections sitemap should contain less than 50,000 targets' if @collections.total_count > 50_000
  end

  def items
    @items = Item.public
    Rollbar.warning 'items sitemap should contain less than 50,000 targets' if @items.total_count > 50_000
  end

  def theses
    @theses = Thesis.public
    Rollbar.warning 'thesis sitemap should contain less than 50,000 targets' if @theses.total_count > 50_000
  end

end
