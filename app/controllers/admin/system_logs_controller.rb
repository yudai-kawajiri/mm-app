# frozen_string_literal: true

# Admin System Logs Controller
#
# システムログ（監査ログ）管理
class Admin::SystemLogsController < Admin::BaseController
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

  # システム管理者または会社管理者のみアクセス可能
  def authorize_system_or_company_admin!
    unless current_user.super_admin? || current_user.company_admin?
      redirect_to root_path, alert: t('errors.unauthorized')
    end
  end

  # 権限に応じてアクセス可能なログを返す
  def accessible_versions
    case current_user.role
    when 'company_admin'
      # 会社管理者: 店舗選択時はその店舗のみ、未選択時は全店舗
      if current_store.present?
        PaperTrail::Version.where(store_id: current_store.id)
      else
        store_ids = current_user.tenant.stores.pluck(:id)
        PaperTrail::Version.where(store_id: store_ids)
      end
    when 'super_admin'
      # スーパー管理者: 全履歴
      PaperTrail::Version.all
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
      User.where(id: user_ids)
    else
      User.where(id: user_ids, tenant_id: current_user.tenant_id)
    end
  end
end
