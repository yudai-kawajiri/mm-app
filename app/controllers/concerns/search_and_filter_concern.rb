module SearchAndFilterConcern
  extend ActiveSupport::Concern

  # URLパラメータから検索用パラメータを取得し、正規化する汎用メソッド
  #  許可されたキーを取得し、空文字・空白のみを nil に変換する。
  def get_and_normalize_search_params(*allowed_keys)
    search_params = {}

    params.permit(allowed_keys).each do |key, value|
      # strip.presence で空文字・空白を nil にし、値がある場合のみハッシュに追加
      normalized_value = value.to_s.strip.presence

      # nilではない（つまり有効な値である）場合のみハッシュに追加する
      search_params[key.to_sym] = normalized_value if normalized_value
    end

    search_params
  end

  private
  def search_params; end
end