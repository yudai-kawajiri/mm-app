class MaterialsController < ApplicationController
  def index
    @materials = Material.all
  end

  def show
  end

  def new
    # フォームに渡すための、新しい空の Material インスタンスを準備
    @material = Material.new
  end

  def create
    # 'build'でインスタンスにデータを属性として割り当ててから安全に保存
    @material = current_user.materials.build(params_params)

    if @material.save
      # 'redirect_to'で遷移
      redirect_to materials_path
    else
      # 'render'で再表示
      render :new
    end
  end

  def edit
  end

  def update
  end

  def destroy
  end

  private
  # ストロングパラメータ設定
  def material_params
    params_require(:material).permit(
    :name, :unit_for_product,
    :unit_weight_for_product,
    :unit_for_order,
    :unit_weight_for_order,
    :category_id
  )
  end
end
