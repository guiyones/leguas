class WalksController < ApplicationController
  before_action :set_walk, only: %i[ edit update destroy ]

  def index
    @walks = Current.user.walks.newest_first
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
      params.expect(walk: [ :km, :walked_on, :note ])
    end

    def redirect_after_progress(xp_before)
      redirect_to_celebration_or root_path, notice: progress_notice(xp_before, Current.user.journey.xp)
    end

    def redirect_to_celebration_or(path, notice:)
      if Current.user.next_celebration_key
        redirect_to celebration_path, notice: notice
      else
        redirect_to path, notice: notice
      end
    end

    def progress_notice(xp_before, xp_after)
      level_before = User::Level.new(xp_before).number
      level_after = User::Level.new(xp_after).number

      if level_after > level_before
        "+#{xp_after - xp_before} XP · Nível #{level_after}!"
      else
        "+#{xp_after - xp_before} XP"
      end
    end
end
