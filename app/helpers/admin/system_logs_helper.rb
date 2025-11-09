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
#
module Admin
  module SystemLogsHelper
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
                               when 'create'
                                 ['bg-success', 'admin.system_logs.events.create']
                               when 'update'
                                 ['bg-warning', 'admin.system_logs.events.update']
                               when 'destroy'
                                 ['bg-danger', 'admin.system_logs.events.destroy']
                               else
                                 ['bg-secondary', 'common.unknown']
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
    # @note
    #   - whodunnitがnilの場合は「システム」を返す
    #   - ユーザーが削除されている場合は「不明なユーザー」を返す
    #
    # @example
    #   system_log_user_name(version)
    #   # => "山田太郎"
    #
    def system_log_user_name(version)
      return t('admin.system_logs.index.system') if version.whodunnit.blank?

      user = User.find_by(id: version.whodunnit.to_i)
      user&.name || t('admin.system_logs.index.unknown_user')
    end

    # ============================================================
    # レコード詳細
    # ============================================================

    #
    # バージョン履歴からレコードの詳細情報を取得
    #
    # @param version [PaperTrail::Version] バージョンオブジェクト
    # @return [String] 詳細情報（name, email, または「詳細なし」）
    #
    # @note
    #   - 作成イベント: 現在のレコードから取得
    #   - 更新・削除イベント: objectフィールドから取得
    #   - エラー時は「詳細なし」を返す
    #
    # @example
    #   system_log_detail(version)
    #   # => "商品A"
    #
    def system_log_detail(version)
      if version.event == 'create'
        fetch_detail_from_current_record(version)
      elsif version.object.present?
        fetch_detail_from_object(version)
      else
        t('admin.system_logs.index.no_detail')
      end
    rescue StandardError => e
      Rails.logger.error("Failed to fetch system log detail: #{e.message}")
      t('admin.system_logs.index.no_detail')
    end

    private

    #
    # 現在のレコードから詳細情報を取得（作成イベント用）
    #
    # @param version [PaperTrail::Version] バージョンオブジェクト
    # @return [String] 詳細情報
    #
    def fetch_detail_from_current_record(version)
      record = version.item_type.constantize.find_by(id: version.item_id)
      return t('admin.system_logs.index.deleted_record') if record.nil?

      record.name || record.email || t('admin.system_logs.index.no_detail')
    end

    #
    # objectフィールドから詳細情報を取得（更新・削除イベント用）
    #
    # @param version [PaperTrail::Version] バージョンオブジェクト
    # @return [String] 詳細情報
    #
    def fetch_detail_from_object(version)
      obj = YAML.unsafe_load(version.object)
      obj['name'] || obj['email'] || t('admin.system_logs.index.no_detail')
    end
  end
end
