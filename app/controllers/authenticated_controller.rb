class AuthenticatedController < ApplicationController
  # 認証必須のチェックを移植して
  before_action :authenticate_user!

  # 検索パラメーターの正規化 Concern を組み込む
  include SearchParameterNormalizer

  # カテゴリー取得共通ロジックを組み込む
  include CategoryFetchable

  # 検索フィルタリングロジックを組み込む
  include SearchAndFilterConcern
end
