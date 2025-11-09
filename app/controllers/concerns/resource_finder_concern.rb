# frozen_string_literal: true

# ResourceFinderConcern
#
# リソース検索とセキュリティチェックを提供するConcern
#
# 使用例:
#   class ProductsController < ApplicationController
#     include ResourceFinderConcern
#     find_resource :product, only: [:show, :edit, :update, :destroy]
#   end
#
# 機能:
#   - リソースの自動検索（params[:id]）
#   - RecordNotFoundの捕捉とリダイレクト
#   - before_actionの自動設定
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
    #   # => @product = Product.find(params[:id]) を自動実行
    def find_resource(resource_name, options = {})
      resource_sym = resource_name.to_sym
      callback_method_name = "set_#{resource_sym}"

      define_method callback_method_name do
        begin
          model_class = resource_sym.to_s.classify.constantize
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
