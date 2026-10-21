class CelebrationsController < ApplicationController
  def show
    if key = Current.user.next_celebration_key
      @achievement = Achievement.find(key)
    else
      redirect_to phase_path
    end
  end

  def create
    if Current.user.pending_celebration_keys.include?(params[:key])
      Current.user.celebrate(params[:key])
    end

    redirect_to celebration_path
  end
end
