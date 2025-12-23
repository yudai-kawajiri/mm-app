# frozen_string_literal: true

class Admin::SystemLogsController < Admin::BaseController
  def index
    @versions = accessible_versions
                  .order(created_at: :desc)

    # フィルタ用のデータを設定
    if current_user.super_admin?
      @companies = session[:current_company_id].present? ? [Company.find(session[:current_company_id])] : Company.all
      @stores = session[:current_company_id].present? ? Company.find(session[:current_company_id]).stores : Store.all
      @users = session[:current_company_id].present? ? Company.find(session[:current_company_id]).users : User.all
    elsif current_user.company_admin?
      @companies = [current_user.company]
      @stores = current_user.company.stores
      @users = current_user.company.users
    else
      @companies = [current_user.company]
      @stores = [current_user.store]
      @users = current_user.store.users
    end

    # モデルタイプの一覧
    @model_types = PaperTrail::Version.distinct.pluck(:item_type).compact.sort

    # フィルタ処理
    if params[:item_type].present?
      @versions = @versions.where(item_type: params[:item_type])
    end

    if params[:whodunnit].present?
      @versions = @versions.where(whodunnit: params[:whodunnit])
    end

    if params[:company_id].present?
      company_user_ids = User.where(company_id: params[:company_id]).pluck(:id).map(&:to_s)
      @versions = @versions.where(whodunnit: company_user_ids)
    end

    if params[:store_id].present?
      store_user_ids = User.where(store_id: params[:store_id]).pluck(:id).map(&:to_s)
      @versions = @versions.where(whodunnit: store_user_ids)
    end

    if params[:date_from].present?
      date_from = Date.parse(params[:date_from]).beginning_of_day
      @versions = @versions.where("created_at >= ?", date_from)
    end

    if params[:date_to].present?
      date_to = Date.parse(params[:date_to]).end_of_day
      @versions = @versions.where("created_at <= ?", date_to)
    end

    @versions = @versions.page(params[:page]).per(20)
  end

  private

  def accessible_versions
    if current_user.super_admin?
      # システム管理(全会社)モード: 全ログ表示
      return PaperTrail::Version.all if session[:current_company_id].blank?

      # 特定テナント選択時: そのテナントのユーザーが実行したログのみ
      company = Company.find(session[:current_company_id])
      company_user_ids = company.users.pluck(:id).map(&:to_s)

      # 店舗が選択されている場合、その店舗のユーザーのログのみ
      if session[:current_store_id].present?
        store_user_ids = company.users.where(store_id: session[:current_store_id]).pluck(:id).map(&:to_s)
        return PaperTrail::Version.where(whodunnit: store_user_ids)
      end

      PaperTrail::Version.where(whodunnit: company_user_ids)
    elsif current_user.company_admin?
      # 会社管理者: 自社ユーザーが実行したログのみ
      company = current_user.company
      company_user_ids = company.users.pluck(:id).map(&:to_s)

      # 店舗が選択されている場合、その店舗のユーザーのログのみ
      if session[:current_store_id].present?
        store_user_ids = company.users.where(store_id: session[:current_store_id]).pluck(:id).map(&:to_s)
        return PaperTrail::Version.where(whodunnit: store_user_ids)
      end

      PaperTrail::Version.where(whodunnit: company_user_ids)
    elsif current_user.store_admin?
      # 店舗管理者: 自店舗ユーザーが実行したログのみ
      store = current_user.store
      store_user_ids = store.users.pluck(:id).map(&:to_s)
      PaperTrail::Version.where(whodunnit: store_user_ids)
    else
      PaperTrail::Version.none
    end
  end
end
