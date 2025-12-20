# frozen_string_literal: true

# Admin System Logs Controller
#
# システムログ（監査ログ）管理
class Admin::SystemLogsController < Admin::BaseController
  before_action :authorize_system_or_company_admin!

  LOGS_PER_PAGE = 50

  def index
    @versions = accessible_versions
      .order(created_at: :desc)
      .page(params[:page])
      .per(LOGS_PER_PAGE)

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

    @model_types = accessible_model_types
    @users = accessible_users
  end

  private

  # システム管理者または会社管理者のみアクセス可能（店舗管理者は不可）
  def authorize_system_or_company_admin!
    unless current_user.super_admin? || current_user.company_admin?
      redirect_to authenticated_root_path, alert: t('errors.messages.unauthorized')
    end
  end

  # 権限に応じてアクセス可能なログを返す
  def accessible_versions
    if current_user.super_admin?
      # システム管理者: session[:current_tenant_id]でフィルタ
      if session[:current_tenant_id].present?
        # 特定テナント選択時
        tenant = Tenant.find(session[:current_tenant_id])
        if session[:current_store_id].present?
          # 特定店舗選択時
          store = Store.find(session[:current_store_id])
          PaperTrail::Version
            .joins("LEFT JOIN users ON CAST(versions.whodunnit AS INTEGER) = users.id")
            .where("users.store_id = ? OR versions.whodunnit IS NULL", store.id)
        else
          # テナント全体のログ
          PaperTrail::Version
            .joins("LEFT JOIN users ON CAST(versions.whodunnit AS INTEGER) = users.id")
            .where("users.tenant_id = ? OR versions.whodunnit IS NULL", tenant.id)
        end
      else
        # 全テナントのログ
        PaperTrail::Version.all
      end
    elsif current_user.company_admin?
      # 会社管理者: テナント内のログをフィルタ
      if session[:current_store_id].present?
        # 特定店舗選択時: その店舗に関連するログのみ
        store = Store.find(session[:current_store_id])
        PaperTrail::Version
          .joins("LEFT JOIN users ON CAST(versions.whodunnit AS INTEGER) = users.id")
          .where("users.store_id = ? OR versions.whodunnit IS NULL", store.id)
      else
        # 全店舗選択時: 会社全体のログ
        PaperTrail::Version
          .joins("LEFT JOIN users ON CAST(versions.whodunnit AS INTEGER) = users.id")
          .where("users.tenant_id = ? OR versions.whodunnit IS NULL", current_tenant.id)
      end
    else
      PaperTrail::Version.none
    end
  end

  # アクセス可能なモデル種別
  def accessible_model_types
    accessible_versions.distinct.pluck(:item_type).compact.sort
  end

  # アクセス可能なユーザー
  def accessible_users
    user_ids = accessible_versions.pluck(:whodunnit).compact.uniq
    if current_user.super_admin?
      if session[:current_tenant_id].present?
        # テナント選択時: そのテナントのユーザーのみ
        User.where(id: user_ids, tenant_id: session[:current_tenant_id])
      else
        # 全テナント
        User.where(id: user_ids)
      end
    else
      User.where(id: user_ids, tenant_id: current_user.tenant_id)
    end
  end
end
