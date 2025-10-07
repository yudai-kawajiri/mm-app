# class BaseResourceController < AuthenticatedController
#   # 継承先のコントローラーが使用するリソース名（例: :material等のシンボル）を動的に決定
#   before_action :set_resource_class

#   before_action :set_resource, only: [:show, :edit, :update, :destroy]

#   # エラーになるのでとりあえずコメントオフ
#   # 継承先でオーバーライドを可能にする
#   # protected

#   # 一行での書き方
#   def show; end

#   def edit; end

#   def new
#     # current_user.idを自動で設定して生成(newだと再度current_user.idが必要)
#     @resource = @resources.build
#     # 失敗時も入力を保持するため(redirect_toだと新しいリクエストのため消える)
#     render :new
#   end

#   def create
#     @resource = @resources.build(resource_params)
#     if @resource.save
#       # クラスから呼ばれメタ情報（例:material,materials）を保存し、文字列で渡す
#       flash[:notice] = t('flash_messages.update.success',
#                           resource: @resource_class.model_name.human)
#       redirect_to @resource
#     else
#       flash.now[:alert] = t('flash_messages.update.failure',
#                           resource: @resource_class.model_name.human)

#       # renderは200を返すため、スターテスコード422で失敗をユーザーとコンピュータ双方に伝える
#       render :new, status: :unprocessable_entity
#     end
#   end

#   def update
#     if @resource.update(resource_params)
#       flash[:notice] = t('flash_messages.update.success',
#                           resource: @resource_class.model_name.human,
#                           name: @resource.name)
#       redirect_to @resource
#     else
#       flash.now[:alert] = t('flash_messages.update.failure',
#                           resource: @resource_class.model_name.human,
#                           name: @resource.name)
#       render :edit, status: :unprocessable_entity
#     end
#   end

#   def destroy
#     if @resource.destroy
#       flash[:notice] = t('flash_messages.destroy.success',
#                           resource: @resource_class.model_name.human,
#                           name: @resource.name)
#       # スターテスコードで次のリクエストをgetに明示的に指示
#       redirect_to collection_path, status: :see_other
#     end
#   end

#   # selfのみで呼び出し可能。レシーバーは指定できない
#   private
#   # 継承先のコントローラーから呼ばれるリソースクラスを決定
#   def set_resource_class
#     # 例: materials->Material->Materialクラスに変換し、ログインユーザーと繋げヘルパーメソッドを使用可能にする
#     @resource_class = controller_path.classify.constantize
#     @resources = current_user.send(controller_name)
#   end

#   # @resourceの取得共通化
#   def set_resource
#     # @resources(例: current_user.materials)から:idに基づいて検索
#     @resource = @resources.find(params[:id])
#     instance_variable_set("@#{controller_name.singularize}", @resource)
#   end

#   # リソース名（:material）を単数形のシンボルで返す→ストロングパラメータ
#   def resource_name
#     controller_name.singularize.to_sym
#   end

#   # ストロングパラメータを子にオーバーライドさせる仕組み
#   def resource_params
#     # 継承先で実装されてなければraiseがエラーを発生
#     raise NotImplementedError, "#{self.class} must implement"
#   end

#   # リダイレクト先を一覧画面に決定
#   def collection_path
#     url_for(controller: controller_name, action: :index)
#   end
# end
