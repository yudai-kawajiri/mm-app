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

// フォールバック翻訳（日本語デフォルト）
// window.I18n が利用できない環境での最終的なフォールバック
const FALLBACK_TRANSLATIONS = {
  'products.confirm_delete_image': '画像を削除しますか？',
  'products.image_deleted': '画像を削除しました',
  'products.image_delete_failed': '画像の削除に失敗しました',
  'sortable_table.saved': '並び替えを保存しました',
  'sortable_table.save_failed': '並び替えの保存に失敗しました（ステータス: %{status}）',
  'sortable_table.error': 'エラーが発生しました: %{message}',
  'sortable_table.csrf_token_not_found': 'CSRFトークンが見つかりません',
  'components.category_tabs.confirm_delete': 'このカテゴリ―タブを削除しますか？'
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

    // フォールバック翻訳（日本語デフォルト）
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
