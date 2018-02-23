class Admin::ItemsController < Admin::AdminController

  include ItemSearch

  def index
    item_search_setup
  end

end
