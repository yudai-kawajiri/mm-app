module ResourceFinderConcern
  extend ActiveSupport::Concern

  module ClassMethods
    def find_resource(resource_name, options = {})
      resource_sym = resource_name.to_sym
      callback_method_name = "set_#{resource_sym}"

      define_method callback_method_name do
        begin
          model_class = resource_sym.to_s.classify.constantize
          instance_variable_set("@#{resource_sym}", model_class.find(params[:id]))
        rescue ActiveRecord::RecordNotFound
          # ユーザーに紐づかないリソースへのアクセスを捕捉
          flash[:alert] = t("flash_messages.not_authorized")
          redirect_to root_url
        end
      end

      before_action callback_method_name.to_sym, options
    end
  end
end
