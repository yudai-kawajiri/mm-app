class Admin::CompaniesController < ApplicationController
  before_action :authenticate_user!
  before_action :authorize_super_admin!
  before_action :set_company, only: [ :show, :edit, :update, :destroy ]

  def index
    @companies = Company.all

    # 検索処理
    if params[:q].present?
      search_term = "%#{params[:q]}%"
      @companies = @companies.where(
        "companies.name LIKE ? OR companies.slug LIKE ?",
        search_term, search_term
      ).distinct
    end

    # ソート処理
    case params[:sort_by]
    when "slug"
      @companies = @companies.order(slug: :asc)
    when "created_at"
      @companies = @companies.order(created_at: :desc)
    else
      @companies = @companies.order(created_at: :desc) # デフォルト: 登録日降順
    end

    @companies = @companies.page(params[:page]).per(20)
  end

  def show
  end

  def new
    @company = Company.new
  end

  def create
    @company = Company.new(company_params)

    if @company.save
      redirect_to admin_company_path(@company), notice: t("helpers.notice.created", resource: Company.model_name.human)
    else
      render :new, status: :unprocessable_entity
    end
  rescue ActiveRecord::RecordNotUnique => e
    handle_unique_violation(e, :new)
  end

  def edit
  end

  def update
    if @company.update(company_params)
      redirect_to admin_company_path(@company), notice: t("helpers.notice.updated", resource: Company.model_name.human)
    else
      render :edit, status: :unprocessable_entity
    end
  rescue ActiveRecord::RecordNotUnique => e
    handle_unique_violation(e, :edit)
  end

  def destroy
    if @company.destroy
      redirect_to admin_companies_path, notice: t("helpers.notice.destroyed", resource: Company.model_name.human)
    else
      redirect_to admin_company_path(@company), alert: @company.errors.full_messages.join(", ")
    end
  end

  private

  def set_company
    @company = Company.find(params[:id])
  end

  def company_params
    params.require(:company).permit(:name, :slug, :email, :phone)
  end

  def authorize_super_admin!
    unless current_user.super_admin?
      redirect_to company_dashboards_path(company_slug: current_company.slug), alert: t("errors.unauthorized")
    end
  end

  def handle_unique_violation(error, template)
    if error.message.include?('index_companies_on_phone')
      @company.errors.add(:phone, :taken)
    elsif error.message.include?('index_companies_on_slug')
      @company.errors.add(:slug, :taken)
    else
      @company.errors.add(:base, :invalid)
    end
    render template, status: :unprocessable_entity
  end
end
