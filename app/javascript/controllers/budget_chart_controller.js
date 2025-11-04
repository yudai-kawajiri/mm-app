// app/javascript/controllers/budget_chart_controller.js

import { Controller } from "@hotwired/stimulus"
import Chart from "chart.js/auto"

export default class extends Controller {
  connect() {
    this.renderChart()
  }

  disconnect() {
    if (this.chart) {
      this.chart.destroy()
    }
  }

  renderChart() {
    const ctx = document.getElementById('budgetChart')
    if (!ctx) return

    // コントローラーからデータを取得（data属性経由）
    const chartData = JSON.parse(this.element.dataset.chartData || '[]')

    const labels = chartData.map(d => d.date)
    const targetData = chartData.map(d => d.target)
    const actualData = chartData.map(d => d.actual)

    this.chart = new Chart(ctx, {
      type: 'line',
      data: {
        labels: labels,
        datasets: [
          {
            label: '累計目標',
            data: targetData,
            borderColor: 'rgb(13, 110, 253)', // Bootstrap primary color
            backgroundColor: 'rgba(13, 110, 253, 0.1)',
            tension: 0.1,
            fill: false,
            borderWidth: 2
          },
          {
            label: '累計実績',
            data: actualData,
            borderColor: 'rgb(25, 135, 84)', // Bootstrap success color
            backgroundColor: 'rgba(25, 135, 84, 0.1)',
            tension: 0.1,
            fill: false,
            borderWidth: 2
          }
        ]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        plugins: {
          legend: {
            position: 'top',
          },
          tooltip: {
            mode: 'index',
            intersect: false,
            callbacks: {
              label: function(context) {
                let label = context.dataset.label || ''
                if (label) {
                  label += ': '
                }
                if (context.parsed.y !== null) {
                  label += '¥' + context.parsed.y.toLocaleString()
                }
                return label
              }
            }
          }
        },
        scales: {
          x: {
            ticks: {
              maxRotation: 0,
              autoSkip: true,
              maxTicksLimit: 10
            }
          },
          y: {
            beginAtZero: true,
            ticks: {
              callback: function(value) {
                return '¥' + value.toLocaleString()
              }
            }
          }
        }
      }
    })
  }
}
