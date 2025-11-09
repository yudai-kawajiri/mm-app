# frozen_string_literal: true

# ApplicationRecord
#
# すべてのモデルの基底クラス
#
# Rails 5以降のデフォルト構成で、ActiveRecord::Baseを直接継承せず
# アプリケーション固有の共通設定を集約するための抽象クラス
class ApplicationRecord < ActiveRecord::Base
  primary_abstract_class
end
