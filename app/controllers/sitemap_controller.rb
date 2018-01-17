class SitemapController < ApplicationController

  skip_after_action :verify_authorized

  def index
    @communities = Community.all
    @collections = Collection.all
    @items = Item.public
    @theses = Thesis.all
  end

end
