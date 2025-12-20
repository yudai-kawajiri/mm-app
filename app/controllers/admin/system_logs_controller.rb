class Admin::SystemLogsController < Admin::BaseController
  before_action :authorize_super_admin!
  
  LOGS_PER_PAGE = 50

  def index
    @versions = accessible_versions
                  .order(created_at: :desc)

    # フィルタ処理
    if params[:item_type].present?
      @versions = @versions.where(item_type: params[:item_type])
    end

    if params[:whodunnit].present?
      @versions = @versions.where(whodunnit: params[:whodunnit])
    end

    if params[:date_from].present?
      date_from = Date.parse(params[:date_from]).beginning_of_day
      @versions = @versions.where('created_at >= ?', date_from)
    end

    if params[:date_to].present?
      date_to = Date.parse(params[:date_to]).end_of_day
      @versions = @versions.where('created_at <= ?', date_to)
    end

    # ページネーション
    @versions = @versions.page(params[:page]).per(LOGS_PER_PAGE)

    # フィルタ用のデータ
    @model_types = accessible_versions.distinct.pluck(:item_type).compact.sort
    @users = User.where(id: accessible_versions.pluck(:whodunnit).compact.uniq)
  end

  private

  def authorize_super_admin!
    unless current_user&.super_admin?
      redirect_to authenticated_root_path, alert: t('errors.messages.unauthorized')
    end
  end

  def accessible_versions
    if current_user.super_admin?
      # システム管理(全会社)モード: 全ログ表示
      return PaperTrail::Version.all if session[:current_company_id].blank?

      # 特定テナント選択時: そのテナントのユーザーが実行したログのみ
      company = Company.find(session[:current_company_id])
      
      # テナントに所属するユーザーのID一覧(文字列)
      company_user_ids = company.users.pluck(:id).map(&:to_s)
      
      # whodunnit(実行ユーザー)がこのテナントのユーザーのログのみ
      PaperTrail::Version.where(whodunnit: company_user_ids)
    elsif current_user.company_admin?
      # 会社管理者: 自社ユーザーが実行したログのみ
      company = current_user.company
      company_user_ids = company.users.pluck(:id).map(&:to_s)
      
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
