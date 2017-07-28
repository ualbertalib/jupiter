class Admin::AdminController < ApplicationController

  before_action :ensure_admin

  layout 'admin'

  protected

  def ensure_admin
    authorize :admin, :access?
  end

end
