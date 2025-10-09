class UnitsController < AuthenticatedController
  before_action :set_unit, only: [:edit, :update]
  def index
    @units = current_user.units.all
  end

  def new
    @unit = current_user.units.build
  end

  def create
    @unit = current_user.units.build(unit_params)
    if @unit.save
      redirect_to units_path
    else
      render :new
    end
  end

  def edit; end

  def update
    if @unit.update(unit_params)
      redirect_to units_path
    else
      render :edit
    end
  end

  private

  def unit_params
    params.require(:unit).permit(:name, :category)
  end

  def set_unit
    @unit = current_user.units.find(params[:id])
  end
end
