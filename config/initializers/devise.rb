# ====================================================================================
# ログフィルタリング設定（機密情報の保護）
# ====================================================================================
# このファイルを変更した場合は、サーバーの再起動が必要です。
#
# この設定は、Railsのログファイル（log/development.log等）に出力される
# パラメータから機密情報をマスキングします。
#
# 【重要】
# ログファイルは開発中に頻繁に参照されますが、パスワードやクレジットカード番号などの
# 機密情報が平文で記録されると、セキュリティリスクになります。
# この設定により、指定したキーワードに一致するパラメータは "[FILTERED]" に置き換えられます。
#
# 参考：ActiveSupport::ParameterFilter ドキュメント
# https://api.rubyonrails.org/classes/ActiveSupport/ParameterFilter.html

# ====================
# フィルタリング対象のパラメータ
# ====================
# 部分一致でフィルタリングされます
# 例：:passw は password, password_confirmation, current_password などにマッチ

Rails.application.config.filter_parameters += [
  # ====================
  # 認証関連
  # ====================
  :passw,        # password, password_confirmation, current_password
  :secret,       # secret_key, client_secret, api_secret
  :token,        # access_token, refresh_token, csrf_token
  :_key,         # api_key, encryption_key, private_key
  :otp,          # one_time_password, otp_code

  # ====================
  # 暗号化関連
  # ====================
  :crypt,        # encrypted_password, bcrypt_salt
  :salt,         # password_salt, encryption_salt
  :certificate,  # ssl_certificate, client_certificate

  # ====================
  # 個人情報
  # ====================
  :email,        # email, email_address, user_email
  :ssn,          # social_security_number（米国社会保障番号）

  # ====================
  # 決済情報
  # ====================
  :cvv,          # クレジットカードのセキュリティコード（Card Verification Value）
  :cvc,          # クレジットカードのセキュリティコード（Card Verification Code）

  # ====================
  # 寿司管理システム固有の機密情報（必要に応じて追加）
  # ====================
  # :bank_account,  # 銀行口座番号
  # :credit_card,   # クレジットカード番号
  # :phone,         # 電話番号（個人情報保護法対応）
]

# ====================
# フィルタリングの動作例
# ====================
# 【フィルタリング前のログ】
# Parameters: {"user"=>{"email"=>"user@example.com", "password"=>"secret123"}}
#
# 【フィルタリング後のログ】
# Parameters: {"user"=>{"email"=>"[FILTERED]", "password"=>"[FILTERED]"}}
#
# これにより、ログファイルを確認しても機密情報は見えません。

# ====================
# 追加のフィルタリング設定
# ====================
# 正規表現でのフィルタリング（より複雑なパターン）
# Rails.application.config.filter_parameters += [
#   /credit_card_\d+/,  # credit_card_1, credit_card_2 などにマッチ
#   /^api_/,            # api_ で始まるすべてのパラメータ
# ]
#
# ブロックを使用したカスタムフィルタリング
# Rails.application.config.filter_parameters << lambda do |key, value|
#   value.replace("[CUSTOM FILTERED]") if key.match?(/sensitive/)
# end

# ====================
# 本番環境での確認事項
# ====================
# 1. ログファイルに機密情報が記録されていないか定期的にチェック
# 2. 新しい機密情報フィールドを追加した際は、このファイルも更新
# 3. エラーレポートサービス（Sentry, Rollbar等）でも同様のフィルタリングを設定
