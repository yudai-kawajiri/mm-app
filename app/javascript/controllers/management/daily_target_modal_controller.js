// Daily Target Modal Controller
//
// 日別予算編集モーダルの制御コントローラー
//
// 使用例:
//   <div
//     class="modal"
//     id="editDailyTargetModal"
//     data-controller="management--daily-target-modal"
//   >
//     <!-- モーダルの内容 -->
//   </div>
//
//   <button
//     data-bs-toggle="modal"
//     data-bs-target="#editDailyTargetModal"
//     data-date="2024-12-01"
//     data-target-amount="10000"
//   >
//     編集
//   </button>
//
// 機能:
// - モーダル表示時にdata属性から値を読み込み
// - フォームフィールドに値を自動設定
// - 日付の表示フォーマット変換
// - フォームのactionを動的に設定

import { Controller } from "@hotwired/stimulus"
import Logger from "utils/logger"

// 定数定義
const EVENT_TYPE = {
  MODAL_SHOW: 'show.bs.modal',
  MODAL_SHOWN: 'shown.bs.modal'
}

const ELEMENT_ID = {
  FORM: 'editTargetForm',
  YEAR_FIELD: 'editTargetYear',
  MONTH_FIELD: 'editTargetMonth',
  DATE_VALUE_FIELD: 'editTargetDateValue',
  DATE_DISPLAY: 'editTargetDate',
  AMOUNT_FIELD: 'editTargetAmount'
}

const DATA_ATTRIBUTE = {
  DATE: 'date',
  TARGET_AMOUNT: 'targetAmount'
}

const DEFAULT_VALUE = {
  EMPTY_STRING: '',
  ZERO: 0
}

const DATE_OFFSET = {
  MONTH_INDEX: 1
}

const URL_TEMPLATE = {
  UPDATE_DAILY_TARGET: (year, month, day) => `/management/numerical_managements/update_daily_target?year=${year}&month=${month}&day=${day}`
}

const LOG_MESSAGES = {
  CONTROLLER_CONNECTED: 'Daily target modal controller connected',
  MODAL_OPENING: 'Modal opening with data:',
  FIELDS_SET: 'Modal fields set:',
  FORM_ACTION_SET: 'Form action set to:',
  MISSING_DATE: 'data-date attribute is missing'
}

export default class extends Controller {
  // コントローラー接続時の処理
  connect() {
    Logger.log(LOG_MESSAGES.CONTROLLER_CONNECTED)

    // モーダル表示開始イベントをリッスン（データ取得用）
    this.element.addEventListener(EVENT_TYPE.MODAL_SHOW, (event) => {
      this.handleModalShow(event)
    })

    // モーダル表示完了イベントをリッスン（フィールド設定用）
    this.element.addEventListener(EVENT_TYPE.MODAL_SHOWN, (event) => {
      this.applyModalData()
    })
  }

  // モーダル表示時の処理（データ取得）
  handleModalShow(event) {
    const button = event.relatedTarget
    if (!button) return

    const date = button.dataset[DATA_ATTRIBUTE.DATE]
    const targetAmount = button.dataset[DATA_ATTRIBUTE.TARGET_AMOUNT]

    Logger.log(LOG_MESSAGES.MODAL_OPENING, { date, targetAmount })

    if (!date) {
      Logger.error(LOG_MESSAGES.MISSING_DATE)
      return
    }

    // データを一時保存
    this.pendingDate = date
    this.pendingTargetAmount = targetAmount
  }

  // モーダル表示完了後の処理（フィールド設定）
  applyModalData() {
    if (!this.pendingDate) return

    this.setModalData(this.pendingDate, this.pendingTargetAmount)

    // 一時データをクリア
    this.pendingDate = null
    this.pendingTargetAmount = null
  }

  // モーダルデータ設定
  setModalData(date, targetAmount) {
    // 日付を分解
    const dateObj = new Date(date)
    const year = dateObj.getFullYear()
    const month = dateObj.getMonth() + DATE_OFFSET.MONTH_INDEX
    const day = dateObj.getDate()

    // 表示用の日付
    const displayDate = `${month}月${day}日`

    // フォームのactionを動的に設定
    const form = document.getElementById(ELEMENT_ID.FORM)
    if (form) {
      const actionUrl = URL_TEMPLATE.UPDATE_DAILY_TARGET(year, month, day)
      form.action = actionUrl
      Logger.log(LOG_MESSAGES.FORM_ACTION_SET, actionUrl)
    }

    // フォームフィールドに値を設定
    const yearField = document.getElementById(ELEMENT_ID.YEAR_FIELD)
    const monthField = document.getElementById(ELEMENT_ID.MONTH_FIELD)
    const dateValueField = document.getElementById(ELEMENT_ID.DATE_VALUE_FIELD)
    const dateDisplayField = document.getElementById(ELEMENT_ID.DATE_DISPLAY)
    const amountField = document.getElementById(ELEMENT_ID.AMOUNT_FIELD)

    if (yearField) {
      yearField.value = year
      Logger.log('Year field set:', year, yearField)
    } else {
      Logger.error('Year field not found')
    }

    if (monthField) {
      monthField.value = month
      Logger.log('Month field set:', month, monthField)
    } else {
      Logger.error('Month field not found')
    }

    if (dateValueField) {
      dateValueField.value = date
      Logger.log('Date value field set:', date, dateValueField)
    } else {
      Logger.error('Date value field not found')
    }

    if (dateDisplayField) {
      dateDisplayField.value = displayDate
      Logger.log('Date display field set:', displayDate, dateDisplayField)
    } else {
      Logger.error('Date display field not found')
    }

    if (amountField) {
      amountField.value = targetAmount || DEFAULT_VALUE.EMPTY_STRING
      Logger.log('Amount field set:', targetAmount, amountField)
    } else {
      Logger.error('Amount field not found')
    }

    Logger.log(LOG_MESSAGES.FIELDS_SET, {
      year,
      month,
      date,
      displayDate,
      targetAmount: targetAmount || DEFAULT_VALUE.ZERO
    })
  }
}
