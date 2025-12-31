# frozen_string_literal: true

# CrudResponderConcern
#
# CRUDアクションの共通レスポンス処理を提供するConcern
module CrudResponderConcern
  extend ActiveSupport::Concern

  private

  # 保存後の共通応答処理
  #
  # @param resource [ActiveRecord::Base] 対象リソース
  # @param success_path [String, Symbol] 成功時のリダイレクト先（デフォルト: resource）
  # @return [void]
  def respond_to_save(resource, success_path: resource)
    resource_name = resource.class.model_name.human
    resource_display_name = resource.name.presence || I18n.t("common.record")

    if resource.save
      action = resource.previous_changes.key?("id") ? :create : :update

      flash[:notice] = t("flash_messages.#{action}.success",
                        resource: resource_name,
                        name: resource_display_name)

      redirect_to (success_path.respond_to?(:call) ? success_path.call : success_path), status: :see_other, allow_other_host: true
    else
      action = resource.new_record? ? :create : :update

      # 作成・更新失敗 → エラー (赤)
      flash.now[:error] = t("flash_messages.#{action}.failure",
                            resource: resource_name)

      # 失敗時: 422ステータスで new/edit を再レンダリング
      render (resource.new_record? ? :new : :edit), status: :unprocessable_entity
    end
  end

  # 削除後の共通応答処理
  #
  # @param resource [ActiveRecord::Base] 対象リソース
  # @param success_path [String, Symbol] 成功時のリダイレクト先
  # @param destroy_failure_path [String, Symbol] 失敗時のリダイレクト先（デフォルト: success_path）
  # @return [void]
  def respond_to_destroy(resource, success_path:, destroy_failure_path: success_path)
    resource_name = resource.class.model_name.human
    resource_display_name = resource.name.presence || I18n.t("common.record")

    if resource.destroy
      flash[:notice] = t("flash_messages.destroy.success",
                        resource: resource_name,
                        name: resource_display_name)

      redirect_to success_path, status: :see_other, allow_other_host: true
    else
      # 削除失敗 → エラー表示（翻訳ファイルのエラーメッセージをそのまま使用）
      flash[:alert] = resource.errors.full_messages.to_sentence

      redirect_to destroy_failure_path, status: :see_other, allow_other_host: true
    end
  end
end
