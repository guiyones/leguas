class JournalsController < ApplicationController
  def show
    @journey = Current.user.journey
    @completed_weeks = @journey.completed_weeks
    @missions_done = Current.user.missions.accomplished.count
  end
end
