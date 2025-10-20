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
    if @unit.save
      flash[:notice] = t('flash_messages.create.success',
                        resource: Unit.model_name.human,
                        name: @unit.name)
      redirect_to units_path
    else
      flash.now[:alert] = t('flash_messages.create.failure',
                            resource: Unit.model_name.human)
      render :new, status: :unprocessable_entity
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
    if @unit.destroy
      flash[:notice] = t('flash_messages.destroy.success',
                        resource: Unit.model_name.human,
                        name: @unit.name)
      redirect_to units_path
    else
    # flashにエラーメッセージをセット (リダイレクト後も保持される)
    flash[:alert] = @unit.errors.full_messages.to_sentence

    # 一覧画面へリダイレクト
    redirect_to units_path
    end
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
