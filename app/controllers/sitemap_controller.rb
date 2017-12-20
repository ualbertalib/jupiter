class SitemapController < ApplicationController

  def index
    authorize :sitemap, :index?

    @cache_key = Time.current

    @communities = Community.all
    @collections = Collection.all
    @items = Item.all # should be non-private
    # TODO: Theses
  end
end
