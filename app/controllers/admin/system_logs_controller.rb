# frozen_string_literal: true

# Admin System Logs Controller
#
# システムログ（監査ログ）管理
#
# 機能:
# - PaperTrail によるモデル変更履歴の閲覧
# - モデル種別・ユーザー・日付範囲でのフィルタリング
# - ページネーション対応（1ページ50件）
#
# 認証: 管理者のみアクセス可能（before_action :require_admin）
#
# 使用Gem: paper_trail
class Admin::SystemLogsController < AuthenticatedController
  # ページあたりの表示件数
  LOGS_PER_PAGE = 50

  before_action :require_admin

  # システムログ一覧表示
  #
  # PaperTrail::Version から監査ログを取得し、フィルタリング・ページネーションを適用する。
  #
  # @param params [Hash] フィルタパラメータ
  # @option params [String] :item_type モデル種別（例: "Product", "Material"）
  # @option params [String] :whodunnit ユーザーID
  # @option params [String] :date_from 開始日（YYYY-MM-DD形式）
  # @option params [String] :date_to 終了日（YYYY-MM-DD形式）
  # @option params [Integer] :page ページ番号
  #
  # @return [void]
  def index
    @versions = PaperTrail::Version.order(created_at: :desc)

    # モデル種別でフィルタ
    if params[:item_type].present?
      @versions = @versions.where(item_type: params[:item_type])
    end

    # ユーザーでフィルタ
    if params[:whodunnit].present?
      @versions = @versions.where(whodunnit: params[:whodunnit])
    end

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

    # ページネーション
    @versions = @versions.page(params[:page]).per(LOGS_PER_PAGE)

    # フィルタ用データ
    @model_types = PaperTrail::Version.distinct.pluck(:item_type).compact.sort
    @users = User.all
  end
end
