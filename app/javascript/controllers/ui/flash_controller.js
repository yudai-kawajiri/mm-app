// フラッシュメッセージの自動フェードアウト制御
// メッセージタイプ（notice, alert, error）に応じて自動非表示の時間を制御する
//
// 表示時間:
// - notice: 5秒後に自動非表示
// - alert: 7秒後に自動非表示
// - error: 自動非表示しない（手動で閉じる必要がある）
//
// 使用例:
//   <div data-controller="flash" data-flash-type="notice">
//     <div class="alert alert-success">保存しました</div>
//   </div>

import { Controller } from "@hotwired/stimulus"
import Logger from "utils/logger"

// CSS関連
const CSS_CLASSES = {
  SHOW: 'show'
}

// データ属性
const DATA_ATTRIBUTE = {
  FLASH_TYPE: 'flashType'
}

// 表示時間（ミリ秒）
const DURATION_MS = {
  NOTICE: 5000,    // notice メッセージの自動非表示時間
  ALERT: 7000,     // alert メッセージの自動非表示時間
  ERROR: 0,        // error メッセージは自動非表示しない（手動で閉じる必要がある）
  BOOTSTRAP_TRANSITION: 150  // Bootstrap のフェードアウトアニメーション時間
}

// フラッシュタイプ
const FLASH_TYPE = {
  NOTICE: 'notice',
  ALERT: 'alert',
  ERROR: 'error'
}

// ログメッセージ
const LOG_MESSAGES = {
  CONNECTED: 'Flash message controller connected',
  flashTypeAndDuration: (type, duration) => `Flash type: ${type}, duration: ${duration}ms`
}

// フラッシュメッセージの自動フェードアウト制御
export default class extends Controller {
  // コントローラー接続時の処理
  // data-flash-type 属性からメッセージタイプを取得し、対応する自動非表示時間を設定する
  connect() {
    Logger.log(LOG_MESSAGES.CONNECTED)

    const flashType = this.element.dataset[DATA_ATTRIBUTE.FLASH_TYPE]
    const duration = this.getDurationForType(flashType)

    Logger.log(LOG_MESSAGES.flashTypeAndDuration(flashType, duration))

    // duration が 0 の場合は自動的に消さない（エラーメッセージなど）
    if (duration > 0) {
      this.timeout = setTimeout(() => {
        this.fadeOut()
      }, duration)
    }
  }

  // コントローラー切断時の処理
  // タイムアウトをクリアしてメモリリークを防ぐ
  disconnect() {
    if (this.timeout) {
      clearTimeout(this.timeout)
    }
  }

  // フラッシュタイプに応じた表示時間を取得
  getDurationForType(type) {
    switch (type) {
      case FLASH_TYPE.NOTICE:
        return DURATION_MS.NOTICE
      case FLASH_TYPE.ALERT:
        return DURATION_MS.ALERT
      case FLASH_TYPE.ERROR:
        return DURATION_MS.ERROR
      default:
        return DURATION_MS.NOTICE
    }
  }

  // フェードアウトアニメーション
  // Bootstrap の fade クラスを削除してフェードアウトし、アニメーション完了後に DOM から要素を削除する
  fadeOut() {
    this.element.classList.remove(CSS_CLASSES.SHOW)

    // アニメーション完了後に要素を削除
    setTimeout(() => {
      this.element.remove()
    }, DURATION_MS.BOOTSTRAP_TRANSITION)
  }
}
