module SearchParameterNormalizer
  extend ActiveSupport::Concern

  private

  # 全角/半角変換と空白除去を一括で実施
  def normalize_search_query(query)
    return query unless query.present?

    normalized = query.to_s

    # 全角・半角スペースを一度に除去
    normalized = normalized.delete(' 　')

    # 全角英数字を半角英数字に変換
    normalized = normalized.tr('Ａ-Ｚａ-ｚ０-９', 'A-Za-z0-9')

    normalized
  end

  # 検索パラメーターの取得と正規化を担う共通メソッド
  def get_and_normalize_search_params(*permitted_keys)
    permitted_params = params.permit(*permitted_keys)

    if permitted_params[:q].present?
      permitted_params[:q] = normalize_search_query(permitted_params[:q])
    end

    permitted_params
  end
end