class ProductsController < AuthenticatedController
  define_search_params :q, :category_id
  find_resource :product, only: [ :show, :edit, :update, :destroy, :purge_image, :copy ]

  before_action -> { load_categories_for("product", as: :product) }, only: [ :index, :new, :create, :edit, :update ]
  before_action -> { load_categories_for("material", as: :material) }, only: [ :new, :create, :show, :edit, :update ]

  def index
    @products = apply_pagination(
      Product.includes(:category).search_and_filter(search_params).ordered
    )
    @search_categories = @product_categories
    set_search_term_for_view
  end

  def new
    @product = current_user.products.build
    # 新規作成画面に入る時、一時ファイルのキーをクリア
    session[:pending_image_key] = nil
  end

  def create
    @product = current_user.products.build(product_params)

    # 画像パラメータを一時変数に保存
    uploaded_image = params[:product][:image]

    # 新しい画像がアップロードされた場合
    if uploaded_image.present?
      @product.image.attach(uploaded_image)

      # 一時ファイルとして保存（Railsのtmpディレクトリ）
      temp_key = SecureRandom.uuid
      temp_path = Rails.root.join('tmp', 'pending_images', "#{temp_key}_#{uploaded_image.original_filename}")
      FileUtils.mkdir_p(File.dirname(temp_path))
      File.open(temp_path, 'wb') do |file|
        file.write(uploaded_image.read)
      end
      uploaded_image.rewind

      # セッションにキーとメタデータのみ保存
      session[:pending_image_key] = temp_key
      session[:pending_image_filename] = uploaded_image.original_filename
      session[:pending_image_content_type] = uploaded_image.content_type

    elsif session[:pending_image_key].present?
      # 2回目以降のバリデーションエラー：一時ファイルから画像を復元
      temp_key = session[:pending_image_key]
      filename = session[:pending_image_filename]
      content_type = session[:pending_image_content_type]
      temp_path = Rails.root.join('tmp', 'pending_images', "#{temp_key}_#{filename}")

      if File.exist?(temp_path)
        # ファイル内容を一度読み込んでStringIOに変換
        file_content = File.read(temp_path)
        io = StringIO.new(file_content)

        @product.image.attach(
          io: io,
          filename: filename,
          content_type: content_type
        )
      end
    end

    if @product.save
      # 保存成功時、一時ファイルを削除してセッションをクリア
      cleanup_pending_image
      redirect_to @product, notice: t("flash_messages.create.success",
                                      resource: Product.model_name.human,
                                      name: @product.name)
    else
      # バリデーションエラー時、プレビュー用のBase64データを生成
      if @product.image.attached?
        begin
          # 一時ファイルから読み込んでBase64エンコード
          if session[:pending_image_key].present?
            temp_key = session[:pending_image_key]
            filename = session[:pending_image_filename]
            temp_path = Rails.root.join('tmp', 'pending_images', "#{temp_key}_#{filename}")

            if File.exist?(temp_path)
              @image_preview_data = Base64.strict_encode64(File.read(temp_path))
              @image_content_type = session[:pending_image_content_type]
            end
          end
        rescue => e
          Rails.logger.error "Failed to generate image preview: #{e.message}"
        end
      end

      flash.now[:alert] = t("flash_messages.create.failure",
                            resource: Product.model_name.human)
      render :new, status: :unprocessable_entity
    end
  end

  def show
    @product_materials = @product.product_materials.includes(:material, :unit).order(:id)
  end

  def edit; end

  def update
    # 画像が新規アップロードされている場合、一時保存
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

  def destroy
    respond_to_destroy(@product, success_path: products_url)
  end

  def purge_image
    if @product.image.attached?
      @product.image.purge
      head :no_content
    else
      head :not_found
    end
  end

  def copy
    original_product = @product
    base_name = original_product.name
    copy_count = 1
    new_name = "#{base_name} (#{I18n.t('common.copy')}#{copy_count})"

    while Product.exists?(name: new_name, category_id: original_product.category_id)
      copy_count += 1
      new_name = "#{base_name} (#{I18n.t('common.copy')}#{copy_count})"
    end

    new_product = original_product.dup
    new_product.name = new_name
    new_product.user_id = current_user.id

    temp_item_number = "C#{copy_count}"[0..3]

    while Product.exists?(item_number: temp_item_number, category_id: original_product.category_id)
      copy_count += 1
      temp_item_number = "C#{copy_count}"[0..3]
    end

    new_product.item_number = temp_item_number

    ActiveRecord::Base.transaction do
      new_product.save!

      original_product.product_materials.each do |product_material|
        new_product.product_materials.create!(
          material_id: product_material.material_id,
          unit_id: product_material.unit_id,
          quantity: product_material.quantity,
          unit_weight: product_material.unit_weight
        )
      end
    end

    redirect_to products_path, notice: I18n.t('products.messages.copy_success', original_name: original_product.name, new_name: new_product.name, item_number: temp_item_number)
  rescue ActiveRecord::RecordInvalid => e
    redirect_to products_path, alert: I18n.t('products.messages.copy_failed', errors: e.record.errors.full_messages.join(', '))
  end

  def reorder
    product_ids = reorder_params[:product_ids]

    Rails.logger.debug "=== Received product_ids: #{product_ids.inspect}"

    Product.update_display_orders(product_ids)
    head :ok
  end

  private

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

  def reorder_params
    params.permit(product_ids: [])
  end

  def cleanup_pending_image
    if session[:pending_image_key].present?
      temp_key = session[:pending_image_key]
      filename = session[:pending_image_filename]
      temp_path = Rails.root.join('tmp', 'pending_images', "#{temp_key}_#{filename}")

      File.delete(temp_path) if File.exist?(temp_path)

      session[:pending_image_key] = nil
      session[:pending_image_filename] = nil
      session[:pending_image_content_type] = nil
    end
  end
end