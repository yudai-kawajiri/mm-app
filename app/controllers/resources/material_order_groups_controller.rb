# frozen_string_literal: true

# MaterialOrderGroupsController
#
# 発注グループ（MaterialOrderGroup）のCRUD操作を管理
#
# 機能:
#   - 発注グループの一覧表示（検索・ページネーション・ソート機能）
#   - 発注グループの作成・編集・削除
#   - 発注グループのコピー
class Resources::MaterialOrderGroupsController < AuthenticatedController
  include SortableController

  # 検索パラメータの定義
  define_search_params :q, :sort_by

  # ソートオプションの定義
  define_sort_options(
    name: -> { order(:name) },
    created_at: -> { order(created_at: :desc) }
  )

  # リソース検索（show, edit, update, destroy, copy）
  find_resource :material_order_group, only: [:show, :edit, :update, :destroy, :copy]

  # 発注グループ一覧
  #
  # @return [void]
  def index
    sorted_index(
      Resources::MaterialOrderGroup,
      default: 'name',
      scope: :all,
      includes: [:materials]
    )
  end

  # 新規発注グループ作成フォーム
  #
  # @return [void]
  def new
    @material_order_group = current_user.material_order_groups.build
  end

  # 発注グループを作成
  #
  # @return [void]
  def create
    @material_order_group = current_user.material_order_groups.build(material_order_group_params)
    respond_to_save(@material_order_group, success_path: resources_material_order_groups_path)
  end

  # 発注グループ詳細
  #
  # @return [void]
  def show; end

  # 発注グループ編集フォーム
  #
  # @return [void]
  def edit; end

  # 発注グループを更新
  #
  # @return [void]
  def update
    @material_order_group.assign_attributes(material_order_group_params)
    respond_to_save(@material_order_group, success_path: resources_material_order_groups_path)
  end

  # 発注グループを削除
  #
  # @return [void]
  def destroy
    respond_to_destroy(@material_order_group, success_path: resources_material_order_groups_url)
  end

  # 発注グループをコピー
  #
  # @return [void]
  def copy
    copied = @material_order_group.create_copy(user: current_user)
    redirect_to resources_material_order_groups_path, notice: t('material_order_groups.messages.copy_success',
                                                                  original_name: @material_order_group.name,
                                                                  new_name: copied.name)
  rescue ActiveRecord::RecordInvalid => e
    Rails.logger.error "MaterialOrderGroup copy failed: #{e.record.errors.full_messages.join(', ')}"
    redirect_to resources_material_order_groups_path, alert: t('material_order_groups.messages.copy_failed',
                                                                 error: e.record.errors.full_messages.join(', '))
  end

  private

  # Strong Parameters
  #
  # @return [ActionController::Parameters]
  def material_order_group_params
    params.require(:resources_material_order_group).permit(:name, :description)
  end
end
