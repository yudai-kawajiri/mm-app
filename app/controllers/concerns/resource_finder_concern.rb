# frozen_string_literal: true

# ResourceFinderConcern
#
# リソース検索とセキュリティチェックを提供するConcern
#
# 使用例:
#   class Resources::ProductsController < ApplicationController
#     include ResourceFinderConcern
#     find_resource :product, only: [:show, :edit, :update, :destroy]
#   end
#
# 機能:
#   - リソースの自動検索（params[:id]）
#   - RecordNotFoundの捕捉とリダイレクト
#   - before_actionの自動設定
#   - 名前空間付きモデルの自動解決
module ResourceFinderConcern
  extend ActiveSupport::Concern

  module ClassMethods
    # リソース検索用のbefore_actionを定義
    #
    # @param resource_name [Symbol] リソース名（例: :product）
    # @param options [Hash] before_actionのオプション（例: only: [:show, :edit]）
    # @return [void]
    #
    # @example
    #   find_resource :product, only: [:show, :edit, :update, :destroy]
    #   # => @product = Resources::Product.find(params[:id]) を自動実行
    def find_resource(resource_name, options = {})
      resource_sym = resource_name.to_sym
      callback_method_name = "set_#{resource_sym}"

      define_method callback_method_name do
        begin
          # Controllerの名前空間からモデルクラスを推定
          # 例: Resources::ProductsController → Resources::Product
          controller_namespace = self.class.name.deconstantize
          model_name = resource_sym.to_s.classify

          # 名前空間付きモデルクラス名を構築
          full_model_name = if controller_namespace.present?
            "#{controller_namespace}::#{model_name}"
          else
            model_name
          end

          model_class = full_model_name.constantize
          instance_variable_set("@#{resource_sym}", model_class.find(params[:id]))
        rescue ActiveRecord::RecordNotFound
          # 存在しないリソースへのアクセスを捕捉
          flash[:alert] = t("flash_messages.not_authorized")
          redirect_to root_url
        end
      end

      before_action callback_method_name.to_sym, options
    end
  end
end
