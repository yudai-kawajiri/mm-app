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

  users_scope = users_scope.where(approved: true)

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

  def edit
  end
  def create
    @user = current_user.company.users.build(user_params)
    @user.approved = false

    # バリデーションを実行してパスワードを生成
    @user.valid?
    
    # パスワードを保存前に取得
    generated_password = @user.password if @user.password.present?
    
    if @user.save
      flash[:generated_password] = generated_password if generated_password.present?
      redirect_to company_admin_user_path(company_slug: current_company.slug, id: @user), notice: t("helpers.notice.created", resource: User.model_name.human)
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
      redirect_to company_admin_user_path(company_slug: current_company.slug, id: @user), notice: t("helpers.notice.updated", resource: User.model_name.human)
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    # 自分自身は削除できない
    if @user.id == current_user.id
      redirect_to scoped_path(:admin_users_path), alert: t("admin.users.messages.cannot_delete_self"), status: :see_other
      return
    end

    @user.destroy!
    redirect_to scoped_path(:admin_users_path), notice: t("helpers.notice.destroyed", resource: User.model_name.human), status: :see_other
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
        @stores = Company.find(session[:current_company_id]).stores
      else
        @stores = Store.all
      end
    else
      # 会社管理者・店舗管理者
      @stores = current_user.company.stores
    end
  end

  def user_params
    params.require(:user).permit(:name, :email, :password, :password_confirmation, :role, :store_id)
  end
end
