class HealthcheckController < ApplicationController

  skip_after_action :verify_authorized

  def index
    render json: { code: 200, status: 'OK' }, status: :ok
  end

end
