class UnitsController < ApplicationController
  before_action :set_unit, only: [:show, :edit, :update, :destroy]

  # GET /units
  # GET /units.json
  def index
    @units = Unit.all
  end

  # GET /units/1
  # GET /units/1.json
  def show
  end

  # GET /units/new
  def new
    @unit = Unit.new
  end

  # POST /units
  # POST /units.json
  def create
    @unit = Unit.new(unit_params)

    respond_to do |format|
      if @unit.save
        format.html { redirect_to @unit, notice: 'Unit was successfully created.' }
        format.json { render :show, status: :created, location: @unit }
      else
        format.html { render :new }
        format.json { render json: @unit.errors, status: :unprocessable_entity }
      end
    end
  end

  def counters
    @tier = params.fetch(:tier, 1)
    @opponent_units = params.fetch(:opponent_units, [])
    @opponent_race = params.fetch(:opponent_race, "Orc")
    @army_composition_type = params.fetch(:army_composition_type, "Total Power")
    @units = Unit.where(race: @opponent_race).order(:tier, :name)
    @race = params.fetch(:race, "Human")
    @unit_counters = Unit.unit_counters(Unit.where(name: @opponent_units), @race, @tier, @army_composition_type)
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_unit
      @unit = Unit.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def unit_params
      params.require(:unit).permit(:name, :armor_type, :attack_type, :race, :tier, :can_attack, :notes, :immune_to_magic, :air_unit)
    end
end
