# frozen_string_literal: true

# ProductsController
#
# 製品のCRUD操作を管理
#
# 機能:
#   - 製品の一覧表示（検索・カテゴリフィルタ・ページネーション）
#   - 製品の作成・編集・削除
#   - 画像アップロード（ImageUploadService使用）
#   - 製品コピー機能（材料構成も複製）
#   - 表示順の並び替え
#   - 画像削除
class ProductsController < AuthenticatedController
  # 検索パラメータの定義
  define_search_params :q, :category_id

  # リソース検索
  find_resource :product, only: [:show, :edit, :update, :destroy, :purge_image, :copy]

  # カテゴリロード
  before_action -> { load_categories_for("product", as: :product) }, only: [:index, :new, :create, :edit, :update]
  before_action -> { load_categories_for("material", as: :material) }, only: [:new, :create, :show, :edit, :update]

  # 製品一覧
  #
  # @return [void]
  def index
    @products = apply_pagination(
      Product.includes(:category).search_and_filter(search_params).ordered
    )
    @search_categories = @product_categories
    set_search_term_for_view
  end

  # 新規製品作成フォーム
  #
  # @return [void]
  def new
    @product = current_user.products.build
    image_upload_service.clear_session
  end

  # 製品を作成
  #
  # 画像アップロード処理はImageUploadServiceに委譲
  #
  # @return [void]
  def create
    @product = current_user.products.build(product_params)

    # 画像アップロード処理
    uploaded_image = params[:product][:image]
    if uploaded_image.present?
      image_upload_service.handle_upload(@product, uploaded_image)
    elsif image_upload_service.pending_image?
      image_upload_service.restore_pending_image(@product)
    end

    if @product.save
      image_upload_service.cleanup
      redirect_to @product, notice: t("flash_messages.create.success",
                                     resource: Product.model_name.human,
                                     name: @product.name)
    else
      # バリデーションエラー時、プレビューデータを生成
      if @product.image.attached?
        preview_data = image_upload_service.generate_preview_data
        if preview_data
          @image_preview_data = preview_data[:data]
          @image_content_type = preview_data[:content_type]
        end
      end

      flash.now[:alert] = t("flash_messages.create.failure",
                           resource: Product.model_name.human)
      render :new, status: :unprocessable_entity
    end
  end

  # 製品詳細
  #
  # @return [void]
  def show
    @product_materials = @product.product_materials.includes(:material, :unit).order(:id)
  end

  # 製品編集フォーム
  #
  # @return [void]
  def edit; end

  # 製品を更新
  #
  # @return [void]
  def update
    # 画像が新規アップロードされている場合、添付
    if params[:product][:image].present?
      @product.image.attach(params[:product][:image])
    end

    if @product.update(product_params.except(:image))
      redirect_to @product, notice: t("flash_messages.update.success",
                                     resource: Product.model_name.human,
                                     name: @product.name)
    else
      flash.now[:alert] = t("flash_messages.update.failure",
                           resource: Product.model_name.human)
      render :edit, status: :unprocessable_entity
    end
  end

  # 製品を削除
  #
  # @return [void]
  def destroy
    respond_to_destroy(@product, success_path: products_url)
  end

  # 画像を削除
  #
  # @return [void]
  def purge_image
    if @product.image.attached?
      @product.image.purge
      head :no_content
    else
      head :not_found
    end
  end

  # 製品をコピー
  #
  # ユニーク制約を考慮して名前と品番を生成
  # 材料構成も複製
  #
  # @return [void]
  def copy
    original_product = @product
    base_name = original_product.name
    copy_count = 1
    new_name = "#{base_name} (#{I18n.t('common.copy')}#{copy_count})"

    # ユニーク制約を考慮して名前を生成
    while Product.exists?(name: new_name, category_id: original_product.category_id)
      copy_count += 1
      new_name = "#{base_name} (#{I18n.t('common.copy')}#{copy_count})"
    end

    new_product = original_product.dup
    new_product.name = new_name
    new_product.user_id = current_user.id

    # 品番を生成
    temp_item_number = "C#{copy_count}"[0..3]
    while Product.exists?(item_number: temp_item_number, category_id: original_product.category_id)
      copy_count += 1
      temp_item_number = "C#{copy_count}"[0..3]
    end
    new_product.item_number = temp_item_number

    ActiveRecord::Base.transaction do
      new_product.save!

      # 材料構成も複製
      original_product.product_materials.each do |product_material|
        new_product.product_materials.create!(
          material_id: product_material.material_id,
          unit_id: product_material.unit_id,
          quantity: product_material.quantity,
          unit_weight: product_material.unit_weight
        )
      end
    end

    redirect_to products_path, notice: I18n.t('products.messages.copy_success',
                                              original_name: original_product.name,
                                              new_name: new_product.name,
                                              item_number: temp_item_number)
  rescue ActiveRecord::RecordInvalid => e
    redirect_to products_path, alert: I18n.t('products.messages.copy_failed',
                                             errors: e.record.errors.full_messages.join(', '))
  end

  # 製品の表示順を並び替え
  #
  # @return [void]
  def reorder
    product_ids = reorder_params[:product_ids]
    Rails.logger.debug "=== Received product_ids: #{product_ids.inspect}"

    Product.update_display_orders(product_ids)
    head :ok
  end

  private

  # Strong Parameters
  #
  # @return [ActionController::Parameters]
  def product_params
    params.require(:product).permit(
      :name,
      :item_number,
      :price,
      :status,
      :description,
      :category_id,
      :image,
      product_materials_attributes: [
        :id,
        :material_id,
        :unit_id,
        :quantity,
        :unit_weight,
        :_destroy
      ]
    )
  end

  # 並び替え用パラメータ
  #
  # @return [ActionController::Parameters]
  def reorder_params
    params.permit(product_ids: [])
  end

  # ImageUploadService のインスタンスを取得
  #
  # @return [ImageUploadService]
  def image_upload_service
    @image_upload_service ||= ImageUploadService.new(session)
  end
end
