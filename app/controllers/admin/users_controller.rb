# frozen_string_literal: true

class Admin::UsersController < Admin::BaseController
  before_action :set_user, only: [ :show, :edit, :update, :destroy ]
  before_action :set_stores, only: [ :new, :create, :edit, :update ]

  def index
  # システム管理者の場合
  if current_user.super_admin?
    if session[:current_company_id].present?
      # 特定テナント選択時: そのテナントのユーザーのみ
      users_scope = Company.find(session[:current_company_id]).users
      if session[:current_store_id].present?
        users_scope = users_scope.where(store_id: session[:current_store_id])
      end
    else
      # システム管理(全会社)モード: 全ユーザー
      users_scope = User.all
    end
  else
    # 会社管理者・店舗管理者
    users_scope = current_user.company.users

    if current_user.store_admin?
      users_scope = users_scope.where(store_id: current_user.store_id)
    elsif current_user.company_admin? && session[:current_store_id].present?
      users_scope = users_scope.where(store_id: session[:current_store_id])
    end
  end

  # 承認済みユーザー + AdminRequest が pending/approved のユーザー
  # 承認済みユーザー + AdminRequest が pending/approved のユーザー + AdminRequestが存在しないユーザー（管理者が直接作成）
  admin_request_user_ids = AdminRequest.where.not(status: :rejected).pluck(:user_id)
  users_with_no_request = users_scope.left_joins(:admin_requests).where(admin_requests: { id: nil }).pluck(:id)

  users_scope = users_scope.where(
    "users.approved = ? OR users.id IN (?) OR users.id IN (?)",
    true,
    admin_request_user_ids.presence || [0],
    users_with_no_request.presence || [0]
  )

  # 検索処理
  if params[:q].present?
    search_term = "%#{params[:q]}%"
    users_scope = users_scope.where(
      "users.name LIKE ? OR users.email LIKE ?",
      search_term, search_term
    )
  end

  # ソート処理
  case params[:sort_by]
  when "company"
    users_scope = users_scope.left_joins(:company).order("companies.name ASC")
  when "email"
    users_scope = users_scope.order(email: :asc)
  when "created_at"
    users_scope = users_scope.order(created_at: :desc)
  else
    users_scope = users_scope.order(created_at: :desc)
  end

    @users = users_scope.page(params[:page]).per(20)
  end

  def show
    # 承認済みユーザーのみ表示
    @users = @user.store.users.where(approved: true).includes(:company).order(:created_at) if @user.store
  end

  def new
    @user = current_user.company.users.build
  end

  def edit; end

  def create
    @user = current_user.company.users.build(user_params)
    @user.approved = true

    # パスワードが空の場合のみ自動生成
    password_was_blank = params[:user][:password].blank?

    if @user.save
      # パスワードが自動生成された場合のみフラッシュメッセージを表示
      if password_was_blank && @user.password.present?
        flash[:generated_password] = @user.password
      end
        redirect_to company_admin_user_path(@user, company_slug: current_company.slug), notice: t("flash_messages.admin.users.messages.created")
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    # パスワードが空欄の場合はパラメータから除外
    update_params = user_params
    if update_params[:password].blank?
      update_params = update_params.except(:password, :password_confirmation)
    end

    if @user.update(update_params)
      redirect_to company_admin_user_path(@user, company_slug: current_company.slug), notice: t("flash_messages.update.success", resource: User.model_name.human)
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    # 自分自身は削除できない
    if @user.id == current_user.id
      redirect_to company_admin_users_path(company_slug: current_company.slug), alert: t("admin.users.messages.cannot_delete_self"), status: :see_other
      return
    end

    @user.destroy!
    redirect_to company_admin_users_path(company_slug: current_company.slug), notice: t("flash_messages.destroy.success", resource: User.model_name.human), status: :see_other
  end

  private

  def set_user
    # システム管理者の場合
    if current_user.super_admin?
      if session[:current_company_id].present?
        @user = Company.find(session[:current_company_id]).users.find(params[:id])
      else
        @user = User.find(params[:id])
      end
    else
      # 会社管理者・店舗管理者
      @user = current_user.company.users.find(params[:id])
    end
  end

  def set_stores
    # システム管理者の場合
    if current_user.super_admin?
      if session[:current_company_id].present?
        company = Company.find(session[:current_company_id])
        if session[:current_store_id].present?
          # 店舗が選択されている場合: その店舗のみ
          @stores = company.stores.where(id: session[:current_store_id])
        else
          # 全店舗選択: 会社の全店舗
          @stores = company.stores
        end
      else
        @stores = Store.all
      end
    elsif current_user.company_admin?
      # 会社管理者
      if session[:current_store_id].present?
        # 店舗が選択されている場合: その店舗のみ
        @stores = current_user.company.stores.where(id: session[:current_store_id])
      else
        # 全店舗選択: 自社の全店舗
        @stores = current_user.company.stores
      end
    else
      # 店舗管理者: 自分の店舗のみ
      @stores = current_user.company.stores.where(id: current_user.store_id)
    end
  end

  def user_params
    params.require(:user).permit(:name, :email, :password, :password_confirmation, :role, :store_id)
  end
end
