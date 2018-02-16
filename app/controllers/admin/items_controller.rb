class Admin::ItemsController < Admin::AdminController

  include ItemSearch

  def index
    @items = Item.limit(10).sort(:record_created_at, :desc)
    item_search_setup
  end

end
