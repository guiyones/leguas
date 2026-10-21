class MenusController < ApplicationController
  def show
    @hide_nav = true
    @journey = Current.user.journey
    @level = @journey.level
  end
end
