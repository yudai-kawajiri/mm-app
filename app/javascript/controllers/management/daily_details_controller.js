import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["toggleBtn", "summary", "form", "dailyTargetSum", "budgetDiff", "saveButton"]
  static values = {
    monthlyBudget: Number,
    shortageText: String,
    excessText: String
  }

  connect() {
    this.isEditMode = false
    this.initializeCumulativeValues()
  }

  toggleEditMode() {
    this.isEditMode = !this.isEditMode

    if (this.isEditMode) {
      this.summaryTarget.style.display = 'block'
      document.querySelectorAll('.normal-mode-display').forEach(el => el.style.display = 'none')
      document.querySelectorAll('.bulk-edit-input').forEach(el => el.style.display = 'block')
      document.querySelectorAll('.bulk-edit-hidden').forEach(el => el.style.display = 'none')
      document.querySelector('.bulk-edit-actions').style.display = 'block'

      this.calculateDailyTargetSum()
    } else {
      this.summaryTarget.style.display = 'none'
      document.querySelectorAll('.normal-mode-display').forEach(el => el.style.display = 'inline')
      document.querySelectorAll('.bulk-edit-input').forEach(el => el.style.display = 'none')
      document.querySelectorAll('.bulk-edit-hidden').forEach(el => el.style.display = 'table-cell')
      document.querySelector('.bulk-edit-actions').style.display = 'none'

      document.querySelectorAll('.bulk-edit-target').forEach(input => {
        const originalValue = parseInt(input.dataset.original, 10) || 0
        input.value = originalValue.toLocaleString('ja-JP')
      })
    }
  }

  calculateDailyTargetSum() {
    let sum = 0, cumulativeTarget = 0, cumulativePlanned = 0, cumulativeActual = 0

    document.querySelectorAll('.bulk-edit-target').forEach(input => {
      const value = parseInt(input.value.replace(/,/g, ''), 10) || 0
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
          const actualInput = actualCell.querySelector('.bulk-edit-actual')
          if (actualInput && !actualInput.disabled) {
            actualValue = parseInt(actualInput.value.replace(/,/g, ''), 10) || 0
          } else {
            const displaySpan = actualCell.querySelector('.normal-mode-display')
            if (displaySpan) actualValue = parseInt(displaySpan.textContent.replace(/[^0-9]/g, ''), 10) || 0
          }
        }
        cumulativeActual += actualValue

        const targetValue = parseInt(input.value.replace(/,/g, ''), 10) || 0
        const achievementRateCell = currentRow.querySelector("td:nth-child(5)")
        if (achievementRateCell) {
          let rate = 0
          if (targetValue > 0) rate = (actualValue / targetValue) * 100
          const rateSpan = achievementRateCell.querySelector("span")
          if (rateSpan) {
            rateSpan.className = ""
            if (rate >= 100) rateSpan.classList.add("text-success")
            else if (rate >= 80) rateSpan.classList.add("text-warning")
            else rateSpan.classList.add("text-danger")
            rateSpan.textContent = rate.toFixed(1) + "%"
          }
        }

        const budgetDiffCell = currentRow.querySelector("td:nth-child(6)")
        if (budgetDiffCell) {
          const diff = actualValue - targetValue
          budgetDiffCell.textContent = "¥" + diff.toLocaleString("ja-JP")
          budgetDiffCell.className = "text-end"
          if (diff >= 0) budgetDiffCell.classList.add("text-success")
          else budgetDiffCell.classList.add("text-danger")
        }

        const cumulativeRow = currentRow.nextElementSibling
        if (cumulativeRow && cumulativeRow.classList.contains('table-light')) {
          this.updateCumulativeCell(cumulativeRow, 1, cumulativeTarget)
          this.updateCumulativeCell(cumulativeRow, 2, cumulativePlanned)
          this.updateCumulativeCell(cumulativeRow, 3, cumulativeActual)

          const cumulativeRateCell = cumulativeRow.querySelector('td:nth-child(4)')
          if (cumulativeRateCell) {
            let rate = 0
            if (cumulativeTarget > 0) rate = (cumulativeActual / cumulativeTarget) * 100
            const rateSpan = cumulativeRateCell.querySelector('span')
            if (rateSpan) {
              rateSpan.className = ''
              if (rate >= 100) rateSpan.classList.add('text-success')
              else if (rate >= 80) rateSpan.classList.add('text-warning')
              else rateSpan.classList.add('text-danger')
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
              if (diff >= 0) cumulativeDiffCell.classList.add('text-success')
              else cumulativeDiffCell.classList.add('text-danger')
            }
          }
        }
      }
    })

    const diff = this.monthlyBudgetValue - sum
    this.dailyTargetSumTarget.textContent = '¥' + sum.toLocaleString('ja-JP')

    if (diff > 0) {
      this.budgetDiffTarget.textContent = '-¥' + diff.toLocaleString('ja-JP') + ' ' + this.shortageTextValue
      this.budgetDiffTarget.className = 'fw-bold text-warning'
      this.saveButtonTarget.disabled = false
    } else if (diff < 0) {
      this.budgetDiffTarget.textContent = '¥' + Math.abs(diff).toLocaleString('ja-JP') + ' ' + this.excessTextValue
      this.budgetDiffTarget.className = 'fw-bold text-danger'
      this.saveButtonTarget.disabled = true
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
    let cumulativeTarget = 0, cumulativePlanned = 0, cumulativeActual = 0

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
          if (cumulativeTarget > 0) rate = (cumulativeActual / cumulativeTarget) * 100
          const rateSpan = cumulativeRateCell.querySelector('span')
          if (rateSpan) {
            rateSpan.className = ''
            if (rate >= 100) rateSpan.classList.add('text-success')
            else if (rate >= 80) rateSpan.classList.add('text-warning')
            else rateSpan.classList.add('text-danger')
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
            if (diff >= 0) cumulativeDiffCell.classList.add('text-success')
            else cumulativeDiffCell.classList.add('text-danger')
          }
        }
      }
    })
  }

  beforeSubmit(event) {
    document.querySelectorAll("[data-controller*='input--number-input']").forEach(input => {
      if (!input.disabled && input.value) input.value = input.value.replace(/,/g, "")
    })
  }
}
