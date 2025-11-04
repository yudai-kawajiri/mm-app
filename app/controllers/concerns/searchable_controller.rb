module SearchableController
  extend ActiveSupport::Concern

  included do
    # クラス全体で共有・継承される属性として、許可するキーの配列を定義
    class_attribute :search_params_keys, default: []
  end

  # クラスメソッドとして呼び出される部分
  module ClassMethods
    # 許可する検索キーを設定するためのクラスメソッド
    def define_search_params(*keys)
      self.search_params_keys = keys
    end
  end

  private

  # 共通化された search_params メソッド
  # 各コントローラーは、このメソッドを継承して利用する
  def search_params
    # 設定されたキーを使って、既存の get_and_normalize_search_params を呼び出す
    get_and_normalize_search_params(*search_params_keys)
  end
end
