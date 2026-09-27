class TravelersController < ApplicationController
  allow_unnamed_traveler
  before_action :redirect_known_traveler

  def new
    @user = Current.user
    @user.avatar ||= User::Traveler::AVATARS.first
  end

  def create
    @user = Current.user
    @user.assign_attributes(traveler_params)

    if @user.save(context: :traveler)
      redirect_to root_path, notice: "Boa jornada, #{@user.name}!"
    else
      render :new, status: :unprocessable_entity
    end
  end

  private
    def redirect_known_traveler
      if Current.user.traveler?
        redirect_to root_path
      end
    end

    def traveler_params
      params.expect(user: [ :name, :avatar, :daily_goal_km ])
    end
end
