class JournalsController < ApplicationController
  def show
    @journey = Current.user.journey
    @missions_done = Current.user.missions.accomplished.count
  end
end
