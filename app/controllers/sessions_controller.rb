class SessionsController < ApplicationController
  require_unauthenticated_access only: :new
  allow_unnamed_traveler only: :destroy

  def new
  end

  def destroy
    terminate_session
    redirect_to new_session_path
  end
end
