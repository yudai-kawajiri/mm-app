import "@hotwired/turbo-rails"
import { Application } from "@hotwired/stimulus"
import Logger from "utils/logger"
import CurrencyFormatter from "utils/currency_formatter"

const GLOBAL_OBJECT = {
  STIMULUS: 'Stimulus'
}

const DEBUG_CONFIG = {
  ENABLED: true
}

const LOG_MESSAGES = {
  DEBUG_MODE_ENABLED: 'Stimulus debug mode enabled'
}

const application = Application.start()
application.debug = DEBUG_CONFIG.ENABLED
window[GLOBAL_OBJECT.STIMULUS] = application
Logger.log(LOG_MESSAGES.DEBUG_MODE_ENABLED)
window.CurrencyFormatter = CurrencyFormatter

// コントローラーの読み込み（export の前に実行）
import "controllers/index"

export { application }
