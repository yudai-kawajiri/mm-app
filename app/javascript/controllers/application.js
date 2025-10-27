// app/javascript/controllers/application.js
import { Application } from "@hotwired/stimulus"

const application = Application.start()

// Rails の環境変数を使用してデバッグモードを設定
// 開発環境では常にデバッグモードを有効化
application.debug = true

// デバッグ用: ブラウザコンソールから Stimulus にアクセス可能
window.Stimulus = application
console.log('🔧 Stimulus debug mode enabled')

export { application }
