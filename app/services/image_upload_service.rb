# frozen_string_literal: true

# ImageUploadService
#
# 製品画像のアップロード・一時保存・復元を管理するサービス
#
# 使用例:
#   service = ImageUploadService.new(session)
#   service.handle_upload(product, uploaded_file)
#   service.restore_pending_image(product)
#   service.cleanup
#
# 機能:
#   - 画像の一時ファイル保存（バリデーションエラー対策）
#   - セッションへのメタデータ保存
#   - 一時ファイルからの復元
#   - Base64プレビューデータ生成
#   - クリーンアップ処理
class ImageUploadService
  # 一時ファイル保存ディレクトリ
  TEMP_DIR = Rails.root.join('tmp', 'pending_images').freeze

  # セッションキー
  SESSION_KEY_IMAGE_KEY = :pending_image_key
  SESSION_KEY_FILENAME = :pending_image_filename
  SESSION_KEY_CONTENT_TYPE = :pending_image_content_type

  attr_reader :session

  # @param session [ActionDispatch::Request::Session] Railsセッション
  def initialize(session)
    @session = session
  end

  # 画像アップロードを処理
  #
  # @param product [Product] 製品オブジェクト
  # @param uploaded_file [ActionDispatch::Http::UploadedFile] アップロードファイル
  # @return [void]
  def handle_upload(product, uploaded_file)
    return unless uploaded_file.present?

    # Active Storageに添付
    product.image.attach(uploaded_file)

    # 一時ファイルとして保存
    save_to_temp_file(uploaded_file)
  end

  # 一時ファイルから画像を復元
  #
  # バリデーションエラー後の再送信時に使用
  #
  # @param product [Product] 製品オブジェクト
  # @return [Boolean] 復元に成功した場合true
  def restore_pending_image(product)
    return false unless pending_image?

    temp_path = build_temp_path
    return false unless File.exist?(temp_path)

    # ファイル内容を読み込んでStringIOに変換
    file_content = File.read(temp_path)
    io = StringIO.new(file_content)

    product.image.attach(
      io: io,
      filename: session[SESSION_KEY_FILENAME],
      content_type: session[SESSION_KEY_CONTENT_TYPE]
    )

    true
  end

  # Base64プレビューデータを生成
  #
  # バリデーションエラー時のプレビュー表示用
  #
  # @return [Hash, nil] プレビューデータ（data, content_type）
  def generate_preview_data
    return nil unless pending_image?

    temp_path = build_temp_path
    return nil unless File.exist?(temp_path)

    {
      data: Base64.strict_encode64(File.read(temp_path)),
      content_type: session[SESSION_KEY_CONTENT_TYPE]
    }
  rescue StandardError => e
    Rails.logger.error "Failed to generate image preview: #{e.message}"
    nil
  end

  # 一時ファイルとセッションをクリーンアップ
  #
  # @return [void]
  def cleanup
    return unless pending_image?

    temp_path = build_temp_path
    File.delete(temp_path) if File.exist?(temp_path)

    clear_session
  end

  # セッションをクリア（ファイルは削除しない）
  #
  # @return [void]
  def clear_session
    session[SESSION_KEY_IMAGE_KEY] = nil
    session[SESSION_KEY_FILENAME] = nil
    session[SESSION_KEY_CONTENT_TYPE] = nil
  end

  # 一時画像が存在するかチェック
  #
  # @return [Boolean]
  def pending_image?
    session[SESSION_KEY_IMAGE_KEY].present?
  end

  private

  # 一時ファイルに保存
  #
  # @param uploaded_file [ActionDispatch::Http::UploadedFile] アップロードファイル
  # @return [void]
  def save_to_temp_file(uploaded_file)
    temp_key = SecureRandom.uuid
    temp_path = TEMP_DIR.join("#{temp_key}_#{uploaded_file.original_filename}")

    FileUtils.mkdir_p(TEMP_DIR)
    File.open(temp_path, 'wb') do |file|
      file.write(uploaded_file.read)
    end
    uploaded_file.rewind

    # セッションにメタデータを保存
    session[SESSION_KEY_IMAGE_KEY] = temp_key
    session[SESSION_KEY_FILENAME] = uploaded_file.original_filename
    session[SESSION_KEY_CONTENT_TYPE] = uploaded_file.content_type
  end

  # 一時ファイルのパスを構築
  #
  # @return [Pathname] 一時ファイルパス
  def build_temp_path
    temp_key = session[SESSION_KEY_IMAGE_KEY]
    filename = session[SESSION_KEY_FILENAME]
    TEMP_DIR.join("#{temp_key}_#{filename}")
  end
end
