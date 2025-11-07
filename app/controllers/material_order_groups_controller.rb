class MaterialOrderGroupsController < AuthenticatedController
  # 検索パラメータの定義
  define_search_params :q

  # リソースの自動取得
  find_resource :material_order_group, only: [:show, :edit, :update, :destroy]


  def index
    # ページネーションと検索を適用
    # 全ユーザーのグループを表示（ログインユーザーなら誰でも閲覧可能）
    @material_order_groups = apply_pagination(
      MaterialOrderGroup.includes(:materials).ordered_by_name.search_and_filter(search_params)
    )
    set_search_term_for_view
  end

  def new
    @material_order_group = MaterialOrderGroup.new
  end

  def create
    @material_order_group = MaterialOrderGroup.new(material_order_group_params)
    @material_order_group.user = current_user  # 作成者を記録
    respond_to_save(@material_order_group, success_path: material_order_groups_path)
  end

  def show
    # find_resourceで自動取得済み
  end

  def edit
    # find_resourceで自動取得済み
  end

  def update
    @material_order_group.assign_attributes(material_order_group_params)
    respond_to_save(@material_order_group, success_path: material_order_groups_path)
  end

  def destroy
    # dependent: :nullify なので、削除すると紐付いている原材料のorder_group_idがnullになる
    respond_to_destroy(@material_order_group, success_path: material_order_groups_path)
  end

  private

  def material_order_group_params
    params.require(:material_order_group).permit(:name)
  end
end
