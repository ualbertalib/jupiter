class Admin::ItemsController < Admin::AdminController

  def index
    @items = Item.limit(10).sort(:record_created_at, :desc)
  end

end
