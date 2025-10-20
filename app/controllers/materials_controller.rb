class MaterialsController <  AuthenticatedController

  find_resource :material, only: [:show, :edit, :update, :destroy]

  def index
    @materials = apply_pagination(current_user.materials
                              .search_and_filter(search_params)
    )
  end

  def show
    # before_actionで完結
  end

  def new
    # フォームに渡すための、新しい空の Material インスタンスを準備
    @material = Material.new
  end

  def create
    # 'build'でインスタンスにデータを属性として割り当ててから安全に保存
    @material = current_user.materials.build(material_params)

    if @material.save
      # 'モデル名を参照する'
      flash[:notice] = t('flash_messages.create.success', resource: Material.model_name.human, name: @material.name)
      redirect_to @material
    else
      # 'render'で再表示
      flash.now[:alert] = t('flash_messages.create.failure', resource: Material.model_name.human)
      # 'ステータスコード422'
      render :new ,status: :unprocessable_entity
    end
  end

  def edit
    # before_actionで完結
  end

  def update
    if @material.update(material_params)
      # railsオブジェクトを渡してパスに変換(idがあれば使用可能)
      flash[:notice] = t('flash_messages.update.success', resource: Material.model_name.human, name: @material.name)
      redirect_to @material
    else
      flash.now[:alert] = t('flash_messages.update.failure', resource: Material.model_name.human)
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @material.destroy
      flash[:notice] = t('flash_messages.destroy.success', resource: Material.model_name.human, name: @material.name)
      # 削除された新しいページを出すのでmaterials_urlで記載
      redirect_to materials_url, status: :see_other
    else
      # 削除に失敗した場合の処理を追加
      flash[:alert] = @material.errors.full_messages.to_sentence
      # 一覧画面に戻す
      redirect_to materials_url, status: :unprocessable_entity # 422ステータスでリダイレクト
    end
  end

  private
  # ストロングパラメータ設定
  def material_params
    params.require(:material).permit(
    :name, :unit_for_product_id,
    :unit_weight_for_product,
    :unit_for_order_id,
    :unit_weight_for_order,
    :category_id,
    :description
  )
  end

  def search_params
    get_and_normalize_search_params(:q,:category_id)
  end

end
