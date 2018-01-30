class WelcomeController < ApplicationController

  skip_after_action :verify_authorized

  layout 'welcome'

end
