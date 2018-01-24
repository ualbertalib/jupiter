class WelcomeController < ApplicationController

  skip_after_action :verify_authorized

  def index
    @should_show_banner = true
  end

end
