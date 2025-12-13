# frozen_string_literal: true

# PaperTrail の設定
PaperTrail.config.enabled = true

# Version モデルに store_id を自動記録
if defined?(PaperTrail)
  module PaperTrail
    class Version < ActiveRecord::Base
      # store_id を自動設定
      before_create :set_store_id

      private

      def set_store_id
        # item (変更されたレコード) から store_id を取得
        if item.respond_to?(:store_id)
          self.store_id = item.store_id
        end
      end
    end
  end
end
