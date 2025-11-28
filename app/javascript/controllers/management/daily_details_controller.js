import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["toggleBtn", "summary", "form", "dailyTargetSum", "budgetDiff", "saveButton"]

  connect() {
    this.isEditMode = false
    this.monthlyBudget = parseInt(this.element.dataset.monthlyBudget, 10) || 0

    // 累計値を初期化
    this.initializeCumulativeValues()
  }

  toggleEditMode() {
    this.isEditMode = !this.isEditMode

    if (this.isEditMode) {
      this.toggleBtnTarget.innerHTML = '<i class="bi bi-eye"></i> 通常表示'
      this.summaryTarget.style.display = 'block'

      document.querySelectorAll('.normal-mode-display').forEach(el => el.style.display = 'none')
      document.querySelectorAll('.bulk-edit-input').forEach(el => el.style.display = 'block')
      document.querySelectorAll('.bulk-edit-hidden').forEach(el => el.style.display = 'none')
      document.querySelector('.bulk-edit-actions').style.display = 'block'

      document.querySelectorAll('.numeric-input').forEach(input => {
        const newInput = document.createElement('input')
        newInput.type = 'text'
        newInput.value = input.value
        newInput.className = input.className
        newInput.name = input.name
        newInput.placeholder = input.placeholder || ''
        newInput.disabled = input.disabled

        if (input.dataset.original) {
          newInput.dataset.original = input.dataset.original
        }

        input.parentNode.replaceChild(newInput, input)
        this.setupNumericInput(newInput)
      })

      this.calculateDailyTargetSum()
    } else {
      this.toggleBtnTarget.innerHTML = '<i class="bi bi-pencil-square"></i> 一括編集'
      this.summaryTarget.style.display = 'none'

      document.querySelectorAll('.normal-mode-display').forEach(el => el.style.display = 'inline')
      document.querySelectorAll('.bulk-edit-input').forEach(el => el.style.display = 'none')
      document.querySelectorAll('.bulk-edit-hidden').forEach(el => el.style.display = 'table-cell')
      document.querySelector('.bulk-edit-actions').style.display = 'none'

      document.querySelectorAll('.bulk-edit-target').forEach(input => {
        const originalValue = parseInt(input.dataset.original, 10) || 0
        input.dataset.rawValue = originalValue.toString()
        input.value = originalValue.toString()
      })
    }
  }

  setupNumericInput(input) {
    let isComposing = false

    const initialValue = input.value.replace(/,/g, '')
    input.dataset.rawValue = initialValue || '0'

    input.addEventListener('compositionstart', () => {
      isComposing = true
    })

    input.addEventListener('compositionend', (e) => {
      isComposing = false
      this.processInput(e.target)
    })

    input.addEventListener('focus', (e) => {
      const rawValue = e.target.dataset.rawValue || '0'
      e.target.value = rawValue

      setTimeout(() => {
        const len = e.target.value.length
        e.target.setSelectionRange(len, len)
      }, 0)
    })

    input.addEventListener('input', (e) => {
      if (isComposing) return
      this.processInput(e.target)
    })

    input.addEventListener('blur', (e) => {
      let rawValue = e.target.dataset.rawValue || ''

      if (rawValue === '' || rawValue === '0') {
        rawValue = '0'
        e.target.dataset.rawValue = '0'
      }

      const numValue = parseInt(rawValue, 10) || 0
      e.target.value = rawValue
    })
  }

  processInput(input) {
    const originalValue = input.value
    const originalCursorPos = input.selectionStart

    let value = originalValue
    value = value.replace(/[０-９]/g, s => String.fromCharCode(s.charCodeAt(0) - 0xFEE0))
    value = value.replace(/[^\d]/g, '')

    if (value.length > 1) {
      value = value.replace(/^0+/, '')
    }

    if (input.value !== value) {
      let digitsBeforeCursor = 0
      for (let i = 0; i < originalCursorPos && i < originalValue.length; i++) {
        if (/\d/.test(originalValue[i])) {
          digitsBeforeCursor++
        }
      }

      input.value = value

      let newPos = 0
      let digitCount = 0
      for (let i = 0; i < value.length; i++) {
        if (digitCount >= digitsBeforeCursor) break
        newPos++
        digitCount++
      }

      input.setSelectionRange(newPos, newPos)
    }

    input.dataset.rawValue = value

    if (input.classList.contains('bulk-edit-target') || input.classList.contains('bulk-edit-actual')) {
      this.calculateDailyTargetSum()
    }
  }

  calculateDailyTargetSum() {
    let sum = 0
    let cumulativeTarget = 0
    let cumulativePlanned = 0
    let cumulativeActual = 0

    document.querySelectorAll('.bulk-edit-target').forEach(input => {
      const value = parseInt(input.dataset.rawValue, 10) || 0
      sum += value
      cumulativeTarget += value

      const currentRow = input.closest('tr')
      if (currentRow) {
        const plannedCell = currentRow.querySelector('td:nth-child(3)')
        const plannedValue = plannedCell ? parseInt(plannedCell.textContent.replace(/[^0-9]/g, ''), 10) || 0 : 0
        cumulativePlanned += plannedValue

        const actualCell = currentRow.querySelector('td:nth-child(4)')
        let actualValue = 0
        if (actualCell) {
          const actualInput = actualCell.querySelector('.numeric-input')
          if (actualInput && !actualInput.disabled) {
            actualValue = parseInt(actualInput.dataset.rawValue, 10) || 0
          } else {
            const displaySpan = actualCell.querySelector('.normal-mode-display')
            if (displaySpan) {
              actualValue = parseInt(displaySpan.textContent.replace(/[^0-9]/g, ''), 10) || 0
            }
          }
        }
        cumulativeActual += actualValue

        const cumulativeRow = currentRow.nextElementSibling
        if (cumulativeRow && cumulativeRow.classList.contains('table-light')) {
          this.updateCumulativeCell(cumulativeRow, 1, cumulativeTarget)
          this.updateCumulativeCell(cumulativeRow, 2, cumulativePlanned)
          this.updateCumulativeCell(cumulativeRow, 3, cumulativeActual)

          const cumulativeRateCell = cumulativeRow.querySelector('td:nth-child(4)')
          if (cumulativeRateCell) {
            let rate = 0
            if (cumulativeTarget > 0) {
              rate = (cumulativeActual / cumulativeTarget) * 100
            }

            const rateSpan = cumulativeRateCell.querySelector('span')
            if (rateSpan) {
              rateSpan.className = ''
              if (rate >= 100) {
                rateSpan.classList.add('text-success')
              } else if (rate >= 80) {
                rateSpan.classList.add('text-warning')
              } else {
                rateSpan.classList.add('text-danger')
              }
              rateSpan.textContent = rate.toFixed(1) + '%'
            }
          }

          const cumulativeDiffCell = cumulativeRow.querySelector('td:nth-child(5)')
          if (cumulativeDiffCell) {
            const diff = cumulativeActual - cumulativeTarget
            const labelElement = cumulativeDiffCell.querySelector('small.text-muted')

            if (labelElement) {
              cumulativeDiffCell.innerHTML = ''
              cumulativeDiffCell.appendChild(labelElement.cloneNode(true))
              cumulativeDiffCell.appendChild(document.createTextNode(' ¥' + diff.toLocaleString('ja-JP')))

              cumulativeDiffCell.className = 'text-end'
              if (diff >= 0) {
                cumulativeDiffCell.classList.add('text-success')
              } else {
                cumulativeDiffCell.classList.add('text-danger')
              }
            }
          }
        }
      }
    })

    const diff = sum - this.monthlyBudget

    this.dailyTargetSumTarget.textContent = '¥' + sum.toLocaleString('ja-JP')

    if (diff > 0) {
      this.budgetDiffTarget.textContent = '+¥' + diff.toLocaleString('ja-JP') + ' 超過'
      this.budgetDiffTarget.className = 'fw-bold text-danger'
      this.saveButtonTarget.disabled = true
    } else if (diff < 0) {
      this.budgetDiffTarget.textContent = '-¥' + Math.abs(diff).toLocaleString('ja-JP') + ' 不足'
      this.budgetDiffTarget.className = 'fw-bold text-warning'
      this.saveButtonTarget.disabled = false
    } else {
      this.budgetDiffTarget.textContent = '¥0'
      this.budgetDiffTarget.className = 'fw-bold text-success'
      this.saveButtonTarget.disabled = false
    }
  }

  updateCumulativeCell(row, columnIndex, value) {
    const cell = row.querySelector('td:nth-child(' + columnIndex + ')')
    if (cell) {
      const labelElement = cell.querySelector('small.text-muted')
      if (labelElement) {
        cell.innerHTML = ''
        cell.appendChild(labelElement.cloneNode(true))
        cell.appendChild(document.createTextNode(' ¥' + value.toLocaleString('ja-JP')))
      }
    }
  }

  initializeCumulativeValues() {
    let cumulativeTarget = 0
    let cumulativePlanned = 0
    let cumulativeActual = 0

    document.querySelectorAll('tbody tr').forEach(row => {
      const dateCell = row.querySelector('td[rowspan="2"]')
      if (!dateCell) return

      const budgetCell = row.querySelector('td:nth-child(2) .normal-mode-display')
      const budgetValue = budgetCell ? parseInt(budgetCell.textContent.replace(/[^0-9]/g, ''), 10) || 0 : 0
      cumulativeTarget += budgetValue

      const plannedCell = row.querySelector('td:nth-child(3)')
      const plannedValue = plannedCell ? parseInt(plannedCell.textContent.replace(/[^0-9]/g, ''), 10) || 0 : 0
      cumulativePlanned += plannedValue

      const actualCell = row.querySelector('td:nth-child(4) .normal-mode-display')
      const actualValue = actualCell ? parseInt(actualCell.textContent.replace(/[^0-9]/g, ''), 10) || 0 : 0
      cumulativeActual += actualValue

      const cumulativeRow = row.nextElementSibling
      if (cumulativeRow && cumulativeRow.classList.contains('table-light')) {
        this.updateCumulativeCell(cumulativeRow, 1, cumulativeTarget)
        this.updateCumulativeCell(cumulativeRow, 2, cumulativePlanned)
        this.updateCumulativeCell(cumulativeRow, 3, cumulativeActual)

        const cumulativeRateCell = cumulativeRow.querySelector('td:nth-child(4)')
        if (cumulativeRateCell) {
          let rate = 0
          if (cumulativeTarget > 0) {
            rate = (cumulativeActual / cumulativeTarget) * 100
          }

          const rateSpan = cumulativeRateCell.querySelector('span')
          if (rateSpan) {
            rateSpan.className = ''
            if (rate >= 100) {
              rateSpan.classList.add('text-success')
            } else if (rate >= 80) {
              rateSpan.classList.add('text-warning')
            } else {
              rateSpan.classList.add('text-danger')
            }
            rateSpan.textContent = rate.toFixed(1) + '%'
          }
        }

        const cumulativeDiffCell = cumulativeRow.querySelector('td:nth-child(5)')
        if (cumulativeDiffCell) {
          const diff = cumulativeActual - cumulativeTarget
          const labelElement = cumulativeDiffCell.querySelector('small.text-muted')

          if (labelElement) {
            cumulativeDiffCell.innerHTML = ''
            cumulativeDiffCell.appendChild(labelElement.cloneNode(true))
            cumulativeDiffCell.appendChild(document.createTextNode(' ¥' + diff.toLocaleString('ja-JP')))

            cumulativeDiffCell.className = 'text-end'
            if (diff >= 0) {
              cumulativeDiffCell.classList.add('text-success')
            } else {
              cumulativeDiffCell.classList.add('text-danger')
            }
          }
        }
      }
    })
  }

  beforeSubmit(event) {
    document.querySelectorAll("[data-controller*='input--number-input']").forEach(input => {
      if (!input.disabled && input.value) {
        input.value = input.value.replace(/,/g, "")
      }
    })
  }
}
