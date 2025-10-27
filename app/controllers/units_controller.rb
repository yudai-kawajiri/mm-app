class UnitsController < AuthenticatedController

  # define_search_params を使って許可するキーを定義
  define_search_params :q, :category

  find_resource :unit, only: [:show, :edit, :update, :destroy]

  def index
    # ページネーションと検索を適用
    @units = apply_pagination(
      Unit.all
        .search_and_filter(search_params)
    )
    # 検索結果のフィードバック表示のため、共通メソッドで @search_term を設定
    set_search_term_for_view
  end

  def new
    @unit = current_user.units.build
  end

  def create
    @unit = current_user.units.build(unit_params)
    respond_to_save(@unit, success_path: units_url)
  end

  def show; end


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
    params.require(:unit).permit(:name, :category, :description)
  end
end
