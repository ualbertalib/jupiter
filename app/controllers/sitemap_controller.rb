class SitemapController < ApplicationController

  skip_after_action :verify_authorized

  def index
    @communities = Community.all
    @collections = Collection.all
    @items = Item.all # should be non-private
    # TODO: Theses or combine both with Chris' abstract superclass work
  end

end
