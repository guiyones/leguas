class MapsController < ApplicationController
  def show
    @journey = Current.user.journey
  end
end
