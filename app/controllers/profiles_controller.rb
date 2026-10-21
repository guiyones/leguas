class ProfilesController < ApplicationController
  def edit
    @user = Current.user
  end

  def update
    @user = Current.user
    @user.assign_attributes(params.expect(user: [ :name, :avatar, :daily_goal_km, :stair_steps ]))

    if @user.save(context: :traveler)
      redirect_to root_path, notice: "Perfil atualizado."
    else
      render :edit, status: :unprocessable_entity
    end
  end
end
