class RoutesController < ApplicationController
  before_action :set_route, only: %i[ edit update destroy ]

  def index
    @routes = Current.user.routes.by_distance
  end

  def new
    @route = Current.user.routes.new
  end

  def create
    @route = Current.user.routes.new(route_params)

    if @route.save
      redirect_to routes_path, notice: "Rota salva."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @route.update(route_params)
      redirect_to routes_path, notice: "Rota atualizada."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @route.destroy
    redirect_to routes_path, notice: "Rota removida. As caminhadas continuam no histórico."
  end

  private
    def set_route
      @route = Current.user.routes.find(params[:id])
    end

    def route_params
      params.expect(route: [ :name, :km, :duration_hours, :duration_minutes, :duration_seconds, :note, :photo, :trace ]).tap do |attributes|
        json = attributes.delete(:trace)
        next if json.blank?

        trace = decoded_trace(json)
        attributes.merge!(trace: trace, trace_source: ("photo" if Route::Trace.valid?(trace)))
      end
    end

    def decoded_trace(json)
      JSON.parse(json)
    rescue JSON::ParserError
      nil
    end
end
