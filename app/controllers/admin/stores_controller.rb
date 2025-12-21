# frozen_string_literal: true

class Admin::StoresController < Admin::BaseController
  before_action :set_store, only: [ :show, :edit, :update, :destroy, :regenerate_invitation_code ]
  before_action :authorize_store_management, only: [ :new, :create, :edit, :update, :destroy, :regenerate_invitation_code ]

def index
    # システム管理者の場合
    if current_user.super_admin?
      if session[:current_company_id].present?
        @stores = Company.find(session[:current_company_id]).stores
      else
        @stores = Store.all
      end
    elsif current_user.store_admin?
      @stores = current_user.company.stores.where(id: current_user.store_id)
    else
      @stores = current_user.company.stores
    end

    # 検索処理
    if params[:q].present?
      search_term = "%#{params[:q]}%"
      @stores = @stores.left_joins(:company).where(
        "stores.name LIKE ? OR stores.code LIKE ? OR companies.slug LIKE ?",
        search_term, search_term, search_term
      ).distinct
    end

    # ソート処理（users_count 計算の前に実行）
    case params[:sort_by]
    when "company"
      @stores = @stores.left_joins(:company).order("companies.name ASC")
    when "code"
      @stores = @stores.order("stores.code ASC")
    when "created_at"
      @stores = @stores.order("stores.created_at DESC")
    else
      @stores = @stores.order("stores.code ASC")
    end

    # users_count を最後に計算（すでに left_joins(:company) されている場合も考慮）
    @stores = @stores.left_joins(:users)
                     .select("stores.*, COUNT(DISTINCT users.id) as users_count")
                     .group("stores.id")
                     .page(params[:page]).per(20)
  end

  def show
    # 承認済みユーザーのみ表示
    @users = @store.users.where(approved: true).includes(:company).order(:created_at)
      .page(params[:page]).per(20)
  end

  def new
    @store = current_user.company.stores.build
  end

  def create
    @store = current_user.company.stores.build(store_params)

    if @store.save
      redirect_to scoped_path(:admin_store_path, @store), notice: t("helpers.notice.created", resource: Store.model_name.human)
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @store.update(store_params)
      redirect_to scoped_path(:admin_store_path, @store), notice: t("helpers.notice.updated", resource: Store.model_name.human)
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @store.users.exists?
      redirect_to scoped_path(:admin_store_path, @store), alert: t("admin.stores.cannot_delete_with_users")
    else
      @store.destroy
      redirect_to scoped_path(:admin_stores_path), notice: t("helpers.notice.destroyed", resource: Store.model_name.human)
    end
  end

  def regenerate_invitation_code
    @store.regenerate_invitation_code!
    redirect_to scoped_path(:admin_store_path, @store), notice: t("admin.stores.invitation_code_regenerated")
  end

  private

  def set_store
    @store = Store.find(params[:id])
  end

  def store_params
    params.require(:store).permit(:name, :code)
  end

  def authorize_store_management
    unless current_user.company_admin? || current_user.super_admin?
      redirect_to scoped_path(:admin_stores_path), alert: t("admin.stores.unauthorized")
    end
  end
end
