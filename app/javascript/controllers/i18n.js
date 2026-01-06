// i18n
//
// フロントエンド国際化対応
//
// 機能:
// - JavaScriptから翻訳キーに基づいてメッセージを取得
// - 修正内容: JS側の日本語 (FALLBACK_TRANSLATIONS) を最優先で見るように変更

// 正規表現パターン
const REGEX = {
  INTERPOLATION: /%\{(\w+)\}/g  // 補間用パターン
}

// フォールバック翻訳（日本語デフォルト）
const FALLBACK_TRANSLATIONS = {
  'products.confirm_delete_image': '画像を削除しますか？',
  'products.image_deleted': '画像を削除しました',
  'products.image_delete_failed': '画像の削除に失敗しました',
  'sortable_table.saved': '並び替えを保存しました',
  'sortable_table.save_failed': '並び替えの保存に失敗しました（ステータス: %{status}）',
  'sortable_table.error': 'エラーが発生しました: %{message}',
  'sortable_table.csrf_token_not_found': 'CSRFトークンが見つかりません',
  'components.category_tabs.confirm_delete': 'このカテゴリタブを削除しますか？',
  'help.video_modal.preparing': '"%{title}" の動画を準備中です',
  'product_material.unit_not_set': '未設定',
  'product_material.unit_error': 'エラー',
  'product_material.errors.unit_fetch_failed': '単位情報の取得に失敗しました',
  'plans.errors.product_fetch_failed': '商品情報の取得に失敗しました。ページを再読み込みしてください。',
  'tabs.category_tabs.confirm_delete': 'このカテゴリーのタブを削除しますか？'
}

// i18n オブジェクト
const i18n = {
  // 翻訳キーからメッセージを取得
  t(key, options = {}) {
    // 【重要】優先順位を入れ替えました：
    // 1. まず JS 側の FALLBACK_TRANSLATIONS をチェック（強制的に日本語を出す）
    if (FALLBACK_TRANSLATIONS[key]) {
      return this.interpolate(FALLBACK_TRANSLATIONS[key], options)
    }

    // 2. 次に window.I18n（Rails側のアセット）をチェック
    if (typeof window['I18n'] !== 'undefined' && window['I18n']['t']) {
      return window['I18n']['t'](key, options)
    }

    // 3. 次に HTML の data-i18n 属性をチェック
    const i18nElement = document.querySelector(`[data-i18n-key="${key}"]`)
    if (i18nElement) {
      return this.interpolate(i18nElement.dataset.i18nValue, options)
    }

    // 全て見つからなければキーをそのまま返す
    return key
  },

  // メッセージ内の変数を補間
  interpolate(message, options) {
    if (!message) return ""
    return message.replace(REGEX.INTERPOLATION, (match, key) => {
      return options[key] !== undefined ? options[key] : match
    })
  }
}

export default i18n