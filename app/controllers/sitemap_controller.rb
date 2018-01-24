class SitemapController < ApplicationController

  skip_after_action :verify_authorized

  def index; end

  def communities
    @communities = Community.all
    # TODO: consider using Rollbar to catch this kind of thing
    logger.warn 'communities sitemap should contain less than 50,000 targets' if @communities.count > 50_000
  end

  def collections
    @collections = Collection.all
    logger.warn 'collections sitemap should contain less than 50,000 targets' if @collections.count > 50_000
  end

  def items
    @items = Item.public
    logger.warn 'items sitemap should contain less than 50,000 targets' if @items.count > 50_000
  end

  def theses
    @theses = Thesis.public
    logger.warn 'thesis sitemap should contain less than 50,000 targets' if @theses.count > 50_000
  end

end
