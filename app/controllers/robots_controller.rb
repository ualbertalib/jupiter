class RobotsController < ApplicationController

  skip_after_action :verify_authorized

  def robots
    respond_to :text
    expires_in 6.hours, public: true
  end

end
