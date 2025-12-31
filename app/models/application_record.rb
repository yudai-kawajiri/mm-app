# frozen_string_literal: true

class ApplicationRecord < ActiveRecord::Base
  # 関連モデル名の日本語翻訳を共通で取得可能にする
  include TranslatableAssociations

  primary_abstract_class
end
