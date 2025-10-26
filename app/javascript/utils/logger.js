// app/javascript/utils/logger.js

class Logger {
  static get isDebug() {
    return true  // 開発中は常に true
  }

  static log(...args) {
    if (this.isDebug) {
      console.log(...args)
    }
  }

  static warn(...args) {
    if (this.isDebug) {
      console.warn(...args)
    }
  }

  static error(...args) {
    console.error(...args)
  }
}

export default Logger