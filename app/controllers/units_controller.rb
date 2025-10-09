class UnitsController < AuthenticatedController
  def index
  end

  def new
    @unit = current_user.units.build
  end

  def create
  end

  def edit
  end
end
