class UnitsController < AuthenticatedController

  find_resource :unit, only: [:edit, :update, :destroy]

  def index
    # ページネーションと検索を適用
    @units = apply_pagination(
      current_user.units
        .search_and_filter(search_params)
    )

    # 検索結果のフィードバック表示のため、検索クエリをビューに渡す
    @search_term = search_params[:q]
  end

  def new
    @unit = current_user.units.build
  end

  def create
    @unit = current_user.units.build(unit_params)
    respond_to_save(@unit, success_path: units_url)
  end

  def edit; end

  def update
    @unit.assign_attributes(unit_params)
    respond_to_save(@unit, success_path: units_url)
  end

  def destroy
    respond_to_destroy(@unit, success_path: units_url)
  end

  private

  def unit_params
    params.require(:unit).permit(:name, :category)
  end

  # 検索パラメーター専用のストロングパラメーターを定義
  def search_params
    get_and_normalize_search_params(:q, :category)
  end
end
