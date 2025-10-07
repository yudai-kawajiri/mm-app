class MaterialsController <  AuthenticatedController
  # ページネーションを使用
  include PaginationConcern
  before_action :set_material, only: [:show, :edit, :update, :destroy]
  def index
    @materials = apply_pagination(current_user.materials
                              # 記載方法の短縮
                              .search_by_name(search_params[:q])
                              .filter_by_category_id(search_params[:category_id])
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
    end


  end

  private
  # ストロングパラメータ設定
  def material_params
    params.require(:material).permit(
    :name, :unit_for_product,
    :unit_weight_for_product,
    :unit_for_order,
    :unit_weight_for_order,
    :category_id
  )
  end

  # @materialの検索（ログインユーザーのもの）
  def set_material
    @material = current_user.materials.find(params[:id])
  end
  # 後でモジュール化
  def search_params
    params.permit(:q, :category_id)
  end
end
