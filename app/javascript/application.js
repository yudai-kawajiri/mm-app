import "@hotwired/turbo-rails"
/**
 * @file application.js
 * Stimulusアプリケーションの初期化と設定
 *
 * @module JavaScript
 */

/**
 * Stimulus アプリケーション設定
 *
 * Stimulusアプリケーションインスタンスの初期化と設定を行う。
 * 開発環境ではデバッグモードを有効化し、ブラウザコンソールから
 * Stimulusインスタンスにアクセス可能にする。
 *
 * 機能:
 * - 開発環境でのデバッグモード有効化
 * - コントローラー接続時のコンソールログ
 * - window.Stimulusでのグローバルアクセス
 *
 * @example ブラウザコンソールからのアクセス
 *   // 登録済みコントローラーの確認
 *   window.Stimulus.router.modules
 *
 *   // コントローラーインスタンスの取得
 *   const controller = window.Stimulus.getControllerForElementAndIdentifier(element, "flash")
 *
 * @see {@link https://stimulus.hotwired.dev/reference/application|Stimulus Application API}
 */

import { Application } from "@hotwired/stimulus"

const application = Application.start()

// Rails環境変数を使用してデバッグモードを設定
// 開発環境では常にデバッグモードを有効化
application.debug = true

// デバッグ用: ブラウザコンソールからStimulusにアクセス可能
window.Stimulus = application
console.log('Stimulus debug mode enabled')

export { application }

// コントローラーの読み込み

// コントローラーの読み込み（importmap経由）
import "controllers/index"
