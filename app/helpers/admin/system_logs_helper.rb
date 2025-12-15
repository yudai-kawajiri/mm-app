# frozen_string_literal: true

#
# Admin::SystemLogsHelper
#
# システムログ画面で使用されるヘルパーメソッド群
#
# @description
#   PaperTrailのバージョン履歴を表示するためのヘルパーメソッドを提供します。
#   - イベントバッジの生成
#   - ユーザー名の取得
#   - レコード詳細情報の取得
#
# @features
#   - Bootstrap対応のバッジ生成
#   - エラーハンドリング
#   - i18n対応
#   - 複数属性対応の柔軟な詳細情報取得
#
module Admin
  module SystemLogsHelper
    # 詳細情報取得時に使用する属性の優先順位
    DETAIL_ATTRIBUTES = %i[name title email code].freeze
    DETAIL_ATTRIBUTES_HASH = %w[name title email code].freeze

    # ============================================================
    # イベント表示
    # ============================================================

    #
    # イベントタイプに応じたBootstrapバッジHTMLを返す
    #
    # @param event [String] イベントタイプ ('create', 'update', 'destroy')
    # @return [String] バッジHTML
    #
    # @example
    #   system_log_event_badge('create')
    #   # => <span class="badge bg-success">作成</span>
    #
    def system_log_event_badge(event)
      badge_class, label_key = case event
      when "create"
                                 [ "bg-success", "admin.system_logs.actions.create" ]
      when "update"
                                 [ "bg-warning", "admin.system_logs.actions.update" ]
      when "destroy"
                                 [ "bg-danger", "admin.system_logs.actions.destroy" ]
      else
                                 [ "bg-secondary", "common.unknown" ]
      end

      content_tag(:span, t(label_key), class: "badge #{badge_class}")
    end

    # ============================================================
    # ユーザー情報
    # ============================================================

    #
    # バージョン履歴からユーザー名を取得
    #
    # @param version [PaperTrail::Version] バージョンオブジェクト
    # @return [String] ユーザー名
    #
    # @description
    #   - whodunnitがnilの場合は「システム」を返す
    #   - ユーザーが削除されている場合は「不明なユーザー」を返す
    #
    # @example
    #   system_log_user_name(version)
    #   # => "山田太郎"
    #
    def system_log_user_name(version)
      return t("admin.system_logs.index.system") if version.whodunnit.blank?

      user = User.find_by(id: version.whodunnit.to_i)
      user&.name || t("admin.system_logs.index.unknown_user")
    end

    # ============================================================
    # レコード詳細
    # ============================================================

    #
    # バージョン履歴からレコードの詳細情報を取得
    #
    # @param version [PaperTrail::Version] バージョンオブジェクト
    # @return [String] 詳細情報（name, title, email, code のいずれか、または「詳細なし」）
    #
    # @description
    #   - 作成イベント: 現在のレコードから取得
    #   - 更新・削除イベント: objectフィールドから取得
    #   - エラー時は「詳細なし」を返す
    #   - 属性の優先順位: name > title > email > code
    #
    # @example
    #   system_log_detail(version)
    #   # => "商品A"
    #
    def system_log_detail(version)
      if version.event == "create"
        fetch_detail_from_current_record(version)
      elsif version.object.present?
        fetch_detail_from_object(version)
      else
        t("admin.system_logs.index.no_detail")
      end
    rescue StandardError => e
      Rails.logger.error("Failed to fetch system log detail: #{e.message}")
      t("admin.system_logs.index.no_detail")
    end

    private

    #
    # 現在のレコードから詳細情報を取得（作成イベント用）
    #
    # @param version [PaperTrail::Version] バージョンオブジェクト
    # @return [String] 詳細情報
    #
    # @description
    #   DETAIL_ATTRIBUTES定数で定義された属性を優先順位順に取得します
    #
    def fetch_detail_from_current_record(version)
      record = version.item_type.constantize.find_by(id: version.item_id)
      return t("admin.system_logs.index.deleted_record") if record.nil?

      # 優先順位付きで属性を取得
      DETAIL_ATTRIBUTES.each do |attr|
        value = record.try(attr)
        return value if value.present?
      end

      t("admin.system_logs.index.no_detail")
    end

    #
    # objectフィールドから詳細情報を取得（更新・削除イベント用）
    #
    # @param version [PaperTrail::Version] バージョンオブジェクト
    # @return [String] 詳細情報
    #
    # @description
    #   DETAIL_ATTRIBUTES_HASH定数で定義された属性を優先順位順に取得します
    #
    def fetch_detail_from_object(version)
      obj = YAML.unsafe_load(version.object)

      # 優先順位付きで属性を取得
      DETAIL_ATTRIBUTES_HASH.each do |attr|
        value = obj[attr]
        return value if value.present?
      end

      t("admin.system_logs.index.no_detail")
    end
  end
end
