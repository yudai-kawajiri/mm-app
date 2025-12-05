// Actual Revenue Modal Controller
//
// 実績入力モーダルの制御コントローラー
//
// 使用例:
//   <div
//     class="modal"
//     id="actualRevenueModal"
//     data-controller="management--actual-revenue-modal"
//   >
//     <form id="actualRevenueForm">
//       <!-- モーダルの内容 -->
//     </form>
//   </div>
//
//   <button
//     data-bs-toggle="modal"
//     data-bs-target="#actualRevenueModal"
//     data-date="2024-12-01"
//     data-plan-schedule-id="123"
//     data-actual-revenue="50000"
//   >
//     実績入力
//   </button>
//
// 機能:
// - モーダル表示時にdata属性から値を読み込み
// - フォームのactionを動的に設定
// - フォームフィールドに値を自動設定
// - 日付の表示フォーマット変換

import { Controller } from "@hotwired/stimulus"
import Logger from "utils/logger"

// 定数定義
const EVENT_TYPE = {
  MODAL_SHOW: 'show.bs.modal',
  MODAL_SHOWN: 'shown.bs.modal'
}

const ELEMENT_ID = {
  FORM: 'actualRevenueForm',
  DATE_DISPLAY: 'actualRevenueDate',
  REVENUE_INPUT: 'actualRevenueInput'
}

const DATA_ATTRIBUTE = {
  DATE: 'date',
  PLAN_SCHEDULE_ID: 'planScheduleId',
  ACTUAL_REVENUE: 'actualRevenue'
}

const DEFAULT_VALUE = {
  EMPTY_STRING: '',
  ZERO: 0
}

const DATE_OFFSET = {
  MONTH_INDEX: 1
}

const URL_TEMPLATE = {
  ACTUAL_REVENUE: (id) => `/management/plan_schedules/${id}/actual_revenue`
}

const LOG_MESSAGES = {
  CONTROLLER_CONNECTED: 'Actual revenue modal controller connected',
  MODAL_OPENING: 'Modal opening with data:',
  FIELDS_SET: 'Actual modal fields set:',
  FORM_ACTION_SET: 'Form action set to:',
  MISSING_SCHEDULE_ID: 'data-plan-schedule-id attribute is missing'
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
    const planScheduleId = button.dataset[DATA_ATTRIBUTE.PLAN_SCHEDULE_ID]
    const actualRevenue = button.dataset[DATA_ATTRIBUTE.ACTUAL_REVENUE]

    Logger.log(LOG_MESSAGES.MODAL_OPENING, { date, planScheduleId, actualRevenue })

    if (!planScheduleId) {
      Logger.error(LOG_MESSAGES.MISSING_SCHEDULE_ID)
      return
    }

    // データを一時保存
    this.pendingDate = date
    this.pendingPlanScheduleId = planScheduleId
    this.pendingActualRevenue = actualRevenue
  }

  // モーダル表示完了後の処理（フィールド設定）
  applyModalData() {
    if (!this.pendingPlanScheduleId) return

    this.setModalData(this.pendingDate, this.pendingPlanScheduleId, this.pendingActualRevenue)

    // 一時データをクリア
    this.pendingDate = null
    this.pendingPlanScheduleId = null
    this.pendingActualRevenue = null
  }

  // モーダルデータ設定
  setModalData(date, planScheduleId, actualRevenue) {
    // 日付を分解して表示用に整形
    const dateObj = new Date(date)
    const month = dateObj.getMonth() + DATE_OFFSET.MONTH_INDEX
    const day = dateObj.getDate()
    const displayDate = `${month}月${day}日`

    // フォームのactionを動的に設定
    const form = document.getElementById(ELEMENT_ID.FORM)
    if (form) {
      const actionUrl = URL_TEMPLATE.ACTUAL_REVENUE(planScheduleId)
      form.action = actionUrl
      Logger.log(LOG_MESSAGES.FORM_ACTION_SET, actionUrl)
    } else {
      Logger.error('Form not found')
    }

    // フォームフィールドに値を設定
    const dateDisplayField = document.getElementById(ELEMENT_ID.DATE_DISPLAY)
    const revenueInputField = document.getElementById(ELEMENT_ID.REVENUE_INPUT)

    if (dateDisplayField) {
      dateDisplayField.value = displayDate
      Logger.log('Date display field set:', displayDate, dateDisplayField)
    } else {
      Logger.error('Date display field not found')
    }

    if (revenueInputField) {
      const rawValue = actualRevenue || DEFAULT_VALUE.EMPTY_STRING
      revenueInputField.value = rawValue

      // input--number-inputコントローラーの初期値フォーマットをトリガー
      if (rawValue) {
        // Stimulusコントローラーのインスタンスを取得
        const numberInputController = this.application.getControllerForElementAndIdentifier(
          revenueInputField,
          'input--number-input'
        )

        if (numberInputController && numberInputController.formatInitialValue) {
          numberInputController.formatInitialValue()
        }
      }

      Logger.log('Revenue input field set:', revenueInputField.value, revenueInputField)
    } else {
      Logger.error('Revenue input field not found')
    }

    Logger.log(LOG_MESSAGES.FIELDS_SET, {
      date,
      displayDate,
      planScheduleId,
      actualRevenue: actualRevenue || DEFAULT_VALUE.ZERO
    })
  }
}
