module ItemLoad
  extend ActiveSupport::Concern

  included do 
    helper_method :load_item
  end

  private

  def load_item
    @item = begin
      Item.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      Thesis.find(params[:id])
    end
  end

end