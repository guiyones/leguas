class WalksController < ApplicationController
  include ProgressRedirect

  before_action :set_walk, only: %i[ edit update destroy ]

  def index
    @entries = Current.user.training_log.entries_newest_first
  end

  def new
    @walk = Current.user.walks.new(walked_on: Date.current)
  end

  def create
    @walk = Current.user.walks.new(walk_params)
    xp_before = Current.user.journey.xp

    if @walk.save
      redirect_after_progress(xp_before)
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @walk.update(walk_params)
      redirect_to_celebration_or walks_path, notice: "Caminhada atualizada."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @walk.destroy
    redirect_to walks_path, notice: "Caminhada removida."
  end

  private
    def set_walk
      @walk = Current.user.walks.find(params[:id])
    end

    def walk_params
      params.expect(walk: [ :km, :walked_on, :load_kg, :note, :duration, :steps, :elevation_gain_m ])
    end
end
