class StairSessionsController < ApplicationController
  include ProgressRedirect

  before_action :set_stair_session, only: %i[ edit update destroy ]

  def new
    @stair_session = Current.user.stair_sessions.new(climbed_on: Date.current)
  end

  def create
    @stair_session = Current.user.stair_sessions.new(stair_session_params)
    xp_before = Current.user.journey.xp

    if save_steps && @stair_session.save
      redirect_after_progress(xp_before)
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @stair_session.update(stair_session_params)
      redirect_to_celebration_or walks_path, notice: "Subida atualizada."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @stair_session.destroy
    redirect_to walks_path, notice: "Subida removida."
  end

  private
    def set_stair_session
      @stair_session = Current.user.stair_sessions.find(params[:id])
    end

    def stair_session_params
      params.expect(stair_session: [ :climbs, :climbed_on, :load_kg, :note ])
    end

    def save_steps
      steps = params.dig(:user, :stair_steps)
      Current.user.stair_steps || steps.blank? || Current.user.update(stair_steps: steps)
    end
end
