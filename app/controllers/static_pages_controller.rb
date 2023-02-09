class StaticPagesController < ApplicationController

  skip_after_action :verify_authorized

  def about; end

  def contact; end

  def policies; end

end
