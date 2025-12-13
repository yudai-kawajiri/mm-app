# frozen_string_literal: true

# Admin System Logs Controller
#
# システムログ（監査ログ）管理
#
# 機能:
# - PaperTrail によるモデル変更履歴の閲覧
# - モデル種別・ユーザー・日付範囲でのフィルタリング
# - 店舗スコープによるアクセス制限
# - ページネーション対応（1ページ50件）
#
# 権限:
# - store_admin: 自店舗の履歴のみ閲覧可能
# - company_admin: 自社全店舗の履歴を閲覧可能
# - super_admin: 全履歴を閲覧可能
class Admin::SystemLogsController < AuthenticatedController
  LOGS_PER_PAGE = 50

  before_action :require_admin

  def index
    @versions = PaperTrail::Version.order(created_at: :desc)

    # 店舗スコープでフィルタ
    @versions = filter_by_store_scope(@versions)

    # モデル種別でフィルタ
    @versions = @versions.where(item_type: params[:item_type]) if params[:item_type].present?

    # ユーザーでフィルタ
    @versions = @versions.where(whodunnit: params[:whodunnit]) if params[:whodunnit].present?

    # 開始日でフィルタ
    if params[:date_from].present?
      date_from = Date.parse(params[:date_from])
      @versions = @versions.where("created_at >= ?", date_from.beginning_of_day)
    end

    # 終了日でフィルタ
    if params[:date_to].present?
      date_to = Date.parse(params[:date_to])
      @versions = @versions.where("created_at <= ?", date_to.end_of_day)
    end

    @versions = @versions.page(params[:page]).per(LOGS_PER_PAGE)

    @model_types = accessible_model_types
    @users = accessible_users
  end

  private

  # 店舗スコープによるフィルタリング
  def filter_by_store_scope(versions)
    return versions if current_user.super_admin?

    if current_user.company_admin?
      # 会社管理者: 自社の全店舗の履歴
      store_ids = current_user.tenant.stores.pluck(:id)
      versions.where(store_id: store_ids)
    elsif current_user.store_admin?
      # 店舗管理者: 自店舗の履歴のみ
      versions.where(store_id: current_user.store_id)
    else
      # 一般ユーザー: アクセス不可
      versions.none
    end
  end

  # アクセス可能なモデル種別
  def accessible_model_types
    versions = current_user.super_admin? ? PaperTrail::Version : filter_by_store_scope(PaperTrail::Version)
    versions.distinct.pluck(:item_type).compact.sort
  end

  # アクセス可能なユーザー
  def accessible_users
    if current_user.super_admin?
      User.all
    elsif current_user.company_admin?
      current_user.tenant.users
    else
      User.where(store_id: current_user.store_id)
    end
  end
end
