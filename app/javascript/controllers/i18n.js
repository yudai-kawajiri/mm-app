/**
 * @file i18n.js
 * フロントエンド国際化対応
 *
 * @module Controllers
 */

/**
 * 簡易的なi18n翻訳関数
 *
 * @description
 *   JavaScriptから翻訳キーに基づいてメッセージを取得します。
 *   翻訳データは data-i18n 属性または window.I18n から取得します。
 *
 * @example
 *   import i18n from "./i18n"
 *   const message = i18n.t('products.confirm_delete_image')
 */

const i18n = {
  /**
   * 翻訳キーからメッセージを取得
   *
   * @param {string} key - 翻訳キー（例: 'products.confirm_delete_image'）
   * @param {object} options - 補間用のオプション（例: { status: 500 }）
   * @returns {string} 翻訳されたメッセージ、または元のキー
   */
  t(key, options = {}) {
    // window.I18n が利用可能な場合（rails-i18n-jsなど）
    if (typeof window.I18n !== 'undefined' && window.I18n.t) {
      return window.I18n.t(key, options)
    }

    // フォールバック: data-i18n 属性から取得
    const i18nElement = document.querySelector(`[data-i18n-key="${key}"]`)
    if (i18nElement) {
      return this.interpolate(i18nElement.dataset.i18nValue, options)
    }

    // フォールバック翻訳（日本語デフォルト）
    const translations = {
      'products.confirm_delete_image': '画像を削除しますか？',
      'products.image_deleted': '画像を削除しました',
      'products.image_delete_failed': '画像の削除に失敗しました',
      'sortable_table.saved': '並び替えを保存しました',
      'sortable_table.save_failed': '並び替えの保存に失敗しました（ステータス: %{status}）',
      'sortable_table.error': 'エラーが発生しました: %{message}',
      'sortable_table.csrf_token_not_found': 'CSRFトークンが見つかりません'
    }

    const message = translations[key] || key
    return this.interpolate(message, options)
  },

  /**
   * メッセージ内の変数を補間
   *
   * @param {string} message - 翻訳メッセージ
   * @param {object} options - 補間用の変数
   * @returns {string} 補間されたメッセージ
   */
  interpolate(message, options) {
    return message.replace(/%\{(\w+)\}/g, (match, key) => {
      return options[key] !== undefined ? options[key] : match
    })
  }
}

export default i18n
