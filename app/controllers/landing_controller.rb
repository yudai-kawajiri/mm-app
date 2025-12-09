class LandingController < ApplicationController
  layout "application"

  def index
    if user_signed_in?
      redirect_to authenticated_root_path
    end
  end
end
