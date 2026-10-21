class PhasesController < ApplicationController
  def show
    @journey = Current.user.journey
    @level = @journey.level
    @week = @journey.current_week
    @mission_goal = Current.user.missions.find_by(date: Date.current)&.goal_km || Current.user.daily_goal_km
    @walked_today = Current.user.walks.where(walked_on: Date.current).sum(:km)
  end
end
