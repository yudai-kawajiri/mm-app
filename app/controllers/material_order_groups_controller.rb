class MaterialOrderGroupsController < AuthenticatedController
  # 全ての発注グループを取得（全ユーザー共有）
  def index
    @groups = MaterialOrderGroup.ordered_by_name

    respond_to do |format|
      format.html # 通常のHTMLビュー
      format.json { render json: @groups } # JSON APIとして使う場合
    end
  end

  # 発注グループの削除（誰でも削除可能）
  def destroy
    @group = MaterialOrderGroup.find(params[:id])

    # このグループを使っている原材料が存在するかチェック
    if @group.materials.exists?
      render json: {
        error: I18n.t('material_order_groups.errors.has_materials', count: @group.materials.count)
      }, status: :unprocessable_entity
    else
      @group.destroy
      render json: { message: I18n.t('material_order_groups.destroyed') }
    end
  rescue ActiveRecord::RecordNotFound
    render json: { error: I18n.t('material_order_groups.errors.not_found') }, status: :not_found
  end
end