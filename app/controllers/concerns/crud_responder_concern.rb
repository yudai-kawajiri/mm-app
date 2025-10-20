module CrudResponderConcern
  extend ActiveSupport::Concern

  private

  # CRUDアクションの保存後の共通応答処理を担う
  def respond_to_save(resource, success_path: resource)
    # リソース名と名前を取得
    resource_name = resource.class.model_name.human
    resource_display_name = resource.name.presence || "レコード"

    if resource.save
      action = resource.previous_changes.key?("id") ? :create : :update

      flash[:notice] = t("flash_messages.#{action}.success",
                        resource: resource_name,
                        name: resource_display_name)


      redirect_to success_path, status: :see_other
    else
      action = resource.new_record? ? :create : :update

      flash.now[:alert] = t("flash_messages.#{action}.failure",
                            resource: resource_name)

      # 失敗時のステータスコード 422 で new または edit テンプレートを再レンダリング
      render (resource.new_record? ? :new : :edit), status: :unprocessable_entity
    end
  end

  # destroy アクションの共通応答処理を担う
  def respond_to_destroy(resource, success_path:, destroy_failure_path: success_path)
    # ... (変更なし) ...
    resource_name = resource.class.model_name.human
    resource_display_name = resource.name.presence || "レコード"

    if resource.destroy
      flash[:notice] = t('flash_messages.destroy.success',
                        resource: resource_name,
                        name: resource_display_name)

      redirect_to success_path, status: :see_other
    else
      # status: :unprocessable_entity (422) を削除し、status: :see_other (303) に変更
      flash[:alert] = resource.errors.full_messages.to_sentence
      # 422を避けて303でリダイレクトすることで、Turbo環境でのFlash表示を保証する
      redirect_to destroy_failure_path, status: :see_other
    end
  end
end