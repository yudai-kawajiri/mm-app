# ====================================================================================
# Content Security Policy (CSP) 設定
# ====================================================================================
# このファイルを変更した場合は、サーバーの再起動が必要です。
#
# CSPは、XSS（クロスサイトスクリプティング）攻撃を防ぐための
# セキュリティ機能です。どのドメインからのリソース読み込みを
# 許可するかを細かく制御できます。
#
# 参考：Rails セキュリティガイド
# https://guides.rubyonrails.org/security.html#content-security-policy-header

# ====================
# CSP 有効化（本番環境推奨）
# ====================
Rails.application.configure do
  config.content_security_policy do |policy|
    # ====================
    # 基本ポリシー
    # ====================
    policy.default_src :self

    # ====================
    # フォント設定
    # ====================
    # Bootstrap Icons（node_modulesから読み込み）のため :data を許可
    policy.font_src :self, :data

    # ====================
    # 画像設定（画像アップロード機能対応）
    # ====================
    # :self = 同一オリジンの画像
    # :data = Base64エンコード画像
    # :https = すべてのHTTPSドメイン
    #
    # 【画像アップロード機能への対応】
    # Active Storage を使用している場合:
    # - 開発環境: ローカルストレージ（:self のみでOK）
    # - 本番環境: S3/GCS等のクラウドストレージ（:https が必要）
    #
    # より安全な設定（本番環境でS3を使用する場合）:
    # policy.img_src :self, :data, 'https://your-bucket.s3.amazonaws.com'
    policy.img_src :self, :data, :https

    # ====================
    # JavaScript設定
    # ====================
    # :self = 同一オリジンのJavaScriptのみ許可
    # :unsafe_inline = インラインスクリプトを許可（非推奨だが段階的移行のため一時的に許可）
    #
    # 【段階的な移行方針】
    # Phase 1: :unsafe_inline で現状のまま動作確認
    # Phase 2: インラインスクリプトをStimulus/外部ファイルに移行
    # Phase 3: :unsafe_inline を削除して完全準拠
    policy.script_src :self, :unsafe_inline

    # ====================
    # CSS設定
    # ====================
    # :self = 同一オリジンのCSSのみ許可
    # :unsafe_inline = インラインスタイルを許可（非推奨だが段階的移行のため一時的に許可）
    #
    # 【段階的な移行方針】
    # Phase 1: :unsafe_inline で現状のまま動作確認
    # Phase 2: インラインスタイルをCSSクラスに移行（約100箇所）
    # Phase 3: :unsafe_inline を削除して完全準拠
    policy.style_src :self, :unsafe_inline

    # ====================
    # オブジェクト埋め込み制限
    # ====================
    policy.object_src :none

    # ====================
    # フォーム送信先制限
    # ====================
    policy.form_action :self

    # ====================
    # フレーム埋め込み制限
    # ====================
    # クリックジャッキング攻撃の防止
    policy.frame_ancestors :none

    # ====================
    # ベースURL制限
    # ====================
    policy.base_uri :self

    # ====================
    # iframe埋め込み設定（YouTube対応）
    # ====================
    # YouTube動画の埋め込みを許可
    # youtube-nocookie.com はプライバシー強化モード用
    policy.frame_src :self, "https://www.youtube.com", "https://www.youtube-nocookie.com"

    # ====================
    # 将来的な拡張例
    # ====================
    # Google Analytics を使用する場合:
    # policy.script_src :self, :unsafe_inline, 'https://www.googletagmanager.com'
    # policy.img_src :self, :data, :https, 'https://www.google-analytics.com'
    # policy.connect_src :self, 'https://www.google-analytics.com'
  end

  # ====================
  # Nonce（ワンタイムトークン）設定
  # ====================
  # インラインスクリプト/スタイルを安全に使用するための設定
  # 現在は :unsafe_inline を使用しているため、Nonceは使用していないが、
  # 将来的にインラインコードを削除する際に有効化する
  config.content_security_policy_nonce_generator = ->(request) { request.session.id.to_s }
  config.content_security_policy_nonce_directives = %w[script-src style-src]

  # ====================
  # レポート専用モード（段階的導入）
  # ====================
  # 【現在の状況】
  # - インラインスタイル: 約100箇所存在
  # - インラインスクリプト: 5箇所存在
  # - インラインイベントハンドラ: 8箇所存在
  #
  # 【段階的移行計画】
  # Phase 1: report_only = true で有効化（現在）
  #          → :unsafe_inline で現状のまま動作することを確認
  #
  # Phase 2: インラインコードの削減
  #          - インラインスクリプト → Stimulus/外部ファイル化
  #          - インラインイベントハンドラ → Stimulus化
  #          - インラインスタイル → CSSクラス化
  #
  # Phase 3: :unsafe_inline の削除
  #          - script_src と style_src から :unsafe_inline を削除
  #          - Nonce ベースの安全なインラインコードに移行
  #
  # Phase 4: 完全有効化
  #          - report_only = false に変更
  config.content_security_policy_report_only = true
end

# ====================
# インラインコード削減のTODO
# ====================
# 【優先度：高】インラインスクリプト（5箇所）
# - app/views/shared/actions/_resource_header_actions.html.erb:28
# - app/views/numerical_managements/_assign_plan_modal.html.erb:76
# - app/views/numerical_managements/_daily_details_table.html.erb:261
# - app/views/numerical_managements/index.html.erb:60
# - app/views/numerical_managements/index.html.erb:72
#
# 【優先度：高】インラインイベントハンドラ（8箇所）
# - onclick属性を使用している箇所をStimulus化
#
# 【優先度：中】インラインスタイル（約100箇所）
# - style属性を使用している箇所をCSSクラス化
# - 特に頻出する min-width, font-size などは共通クラスに
#
# 【完全準拠までの目安】
# - インラインスクリプト/ハンドラ: 1-2日
# - インラインスタイル: 1-2週間
