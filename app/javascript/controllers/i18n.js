// i18n
//
// フロントエンド国際化対応
//
// 使用例:
//   import i18n from "controllers/i18n"
//   const message = i18n.t('products.confirm_delete_image')
//
// 機能:
// - JavaScriptから翻訳キーに基づいてメッセージを取得
// - 翻訳データは window.I18n → data-i18n 属性 → フォールバック翻訳 の順で取得
// - フォールバック翻訳により、window.I18n が利用できない環境でも動作保証

// グローバルオブジェクト名
const GLOBAL_OBJECT = {
  I18N: 'I18n'
}

// グローバルオブジェクトのメソッド名
const METHOD_NAME = {
  TRANSLATE: 't'
}

// 型名（typeof チェック用）
const TYPE_NAME = {
  UNDEFINED: 'undefined'
}

// データ属性名
const DATA_ATTRIBUTES = {
  I18N_KEY: 'i18nKey',
  I18N_VALUE: 'i18nValue'
}

// セレクタ生成用
const SELECTOR = {
  dataI18nKey: (key) => `[data-i18n-key="${key}"]`
}

// 正規表現パターン
const REGEX = {
  INTERPOLATION: /%\{(\w+)\}/g  // 補間用パターン（例: %{status} → options.status）
}

// フォールバック翻訳（英語デフォルト）
// window.I18n が利用できない環境での最終的なフォールバック
const FALLBACK_TRANSLATIONS = {
  'products.confirm_delete_image': 'Delete this image?',
  'products.image_deleted': 'Image deleted',
  'products.image_delete_failed': 'Failed to delete image',
  'sortable_table.saved': 'Order saved',
  'sortable_table.save_failed': 'Failed to save order (status: %{status})',
  'sortable_table.error': 'Error occurred: %{message}',
  'sortable_table.csrf_token_not_found': 'CSRF token not found',
  'components.category_tabs.confirm_delete': 'Delete this category tab?',
  'help.video_modal.preparing': 'Video for "%{title}" is being prepared'
}

// i18n オブジェクト
const i18n = {
  // 翻訳キーからメッセージを取得
  // 翻訳データは以下の優先順位で取得:
  // 1. window.I18n（rails-i18n-jsなど）
  // 2. data-i18n 属性
  // 3. フォールバック翻訳（FALLBACK_TRANSLATIONS）
  t(key, options = {}) {
    // window.I18n が利用可能な場合（rails-i18n-jsなど）
    if (typeof window[GLOBAL_OBJECT.I18N] !== TYPE_NAME.UNDEFINED &&
        window[GLOBAL_OBJECT.I18N][METHOD_NAME.TRANSLATE]) {
      return window[GLOBAL_OBJECT.I18N][METHOD_NAME.TRANSLATE](key, options)
    }

    // フォールバック: data-i18n 属性から取得
    const i18nElement = document.querySelector(SELECTOR.dataI18nKey(key))
    if (i18nElement) {
      return this.interpolate(i18nElement.dataset[DATA_ATTRIBUTES.I18N_VALUE], options)
    }

    // フォールバック翻訳（英語デフォルト）
    const message = FALLBACK_TRANSLATIONS[key] || key
    return this.interpolate(message, options)
  },

  // メッセージ内の変数を補間
  // 例: "エラー: %{message}" + { message: "失敗" } → "エラー: 失敗"
  interpolate(message, options) {
    return message.replace(REGEX.INTERPOLATION, (match, key) => {
      return options[key] !== undefined ? options[key] : match
    })
  }
}

export default i18n
