class UnitsController < AuthenticatedController
  before_action :set_unit, only: [:edit, :update, :destroy]
  def index
    @units = current_user.units.all
  end

  def new
    @unit = current_user.units.build
  end

  def create
    @unit = current_user.units.build(unit_params)
    if @unit.save
      flash[:notice] = t('flash_messages.create.success',
                        resource: Unit.model_name.human,
                        name: @unit.name)
      redirect_to units_path
    else
      flash.now[:alert] = t('flash_messages.create.failure',
                            resource: Unit.model_name.human)
      render :new
    end
  end

  def edit; end

  def update
    if @unit.update(unit_params)
      flash[:notice] = t('flash_messages.update.success',
                        resource: Unit.model_name.human,
                        name: @unit.name)
      redirect_to units_path
    else
      flash.now[:alert] = t('flash_messages.update.failure',
                            resource: Unit.model_name.human)
      render :edit
    end
  end

  def destroy
    @unit.destroy
    flash[:notice] = t('flash_messages.destroy.success',
                      resource: Unit.model_name.human,
                      name: @unit.name)
    redirect_to units_path
  end
  private

  def unit_params
    params.require(:unit).permit(:name, :category)
  end

  def set_unit
    @unit = current_user.units.find(params[:id])
  end
end
