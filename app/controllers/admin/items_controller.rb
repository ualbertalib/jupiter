class Admin::ItemsController < Admin::AdminController

  include ItemSearch

  def index
    restrict_items_to nil # no restrictions on items searched for
  end

end
