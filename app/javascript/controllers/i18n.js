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
   * @returns {string} 翻訳されたメッセージ、または元のキー
   */
  t(key) {
    // window.I18n が利用可能な場合（rails-i18n-jsなど）
    if (typeof window.I18n !== 'undefined' && window.I18n.t) {
      return window.I18n.t(key)
    }

    // フォールバック: data-i18n 属性から取得
    const i18nElement = document.querySelector(`[data-i18n-key="${key}"]`)
    if (i18nElement) {
      return i18nElement.dataset.i18nValue
    }

    // フォールバック翻訳（日本語デフォルト）
    const translations = {
      'products.confirm_delete_image': '画像を削除しますか？',
      'products.image_deleted': '画像を削除しました',
      'products.image_delete_failed': '画像の削除に失敗しました'
    }

    return translations[key] || key
  }
}

export default i18n
