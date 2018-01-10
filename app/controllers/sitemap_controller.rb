class SitemapController < ApplicationController

  skip_after_action :verify_authorized

  def index
    @communities = Community.all
    @collections = Collection.all
    @items = Item.public
    # TODO: Theses or combine both with Chris' abstract superclass work
  end

end
