class Admin::SystemLogsController < AuthenticatedController
  before_action :require_admin

  def index
    @versions = PaperTrail::Version.order(created_at: :desc)
    
    # モデルでフィルタ
    if params[:item_type].present?
      @versions = @versions.where(item_type: params[:item_type])
    end
    
    # ユーザーでフィルタ
    if params[:whodunnit].present?
      @versions = @versions.where(whodunnit: params[:whodunnit])
    end
    
    # 日付でフィルタ
    if params[:date_from].present?
      date_from = Date.parse(params[:date_from])
      @versions = @versions.where('created_at >= ?', date_from.beginning_of_day)
    end
    
    if params[:date_to].present?
      date_to = Date.parse(params[:date_to])
      @versions = @versions.where('created_at <= ?', date_to.end_of_day)
    end
    
    # ページネーション（1ページ50件）
    @versions = @versions.page(params[:page]).per(50)
    
    # フィルタ用データ
    @model_types = PaperTrail::Version.distinct.pluck(:item_type).compact.sort
    @users = User.all
  end
end
