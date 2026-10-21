class TrophiesController < ApplicationController
  def show
    @journey = Current.user.journey
    @phases = @journey.world.phases
  end
end
