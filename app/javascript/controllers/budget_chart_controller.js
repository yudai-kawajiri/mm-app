/**
 * @file budget_chart_controller.js
 * 予算グラフ表示制御
 *
 * @module Controllers
 */

import { Controller } from "@hotwired/stimulus"
import Chart from "chart.js/auto"

/**
 * Budget Chart Controller
 *
 * @description
 *   予算グラフ表示コントローラー。
 *   Chart.js を使用して累計目標と累計実績を折れ線グラフで表示します。
 *
 * @example HTML での使用
 *   <div
 *     data-controller="budget-chart"
 *     data-chart-data='[
 *       {"date":"2024-11-01","target":10000,"actual":8000},
 *       {"date":"2024-11-02","target":20000,"actual":18000}
 *     ]'
 *   >
 *     <canvas id="budgetChart" width="400" height="200"></canvas>
 *   </div>
 *
 * @features
 *   - Chart.js による折れ線グラフ描画
 *   - 累計目標と累計実績の2系列表示
 *   - レスポンシブ対応
 *   - 日本円フォーマット（¥1,000形式）
 *   - ツールチップ表示
 *
 * @requires chart.js/auto - Chart.jsライブラリ
 */
export default class extends Controller {
  /**
   * コントローラー接続時の処理
   *
   * @description
   *   チャートを描画
   */
  connect() {
    this.renderChart()
  }

  /**
   * コントローラー切断時の処理
   *
   * @description
   *   チャートインスタンスを破棄してメモリリークを防ぐ
   */
  disconnect() {
    if (this.chart) {
      this.chart.destroy()
    }
  }

  /**
   * チャート描画処理
   *
   * @description
   *   data-chart-data 属性からデータを取得し、
   *   Chart.js で折れ線グラフを描画します。
   *
   * @note
   *   data-chart-data は以下の形式のJSON配列：
   *   [{ date: "2024-11-01", target: 10000, actual: 8000 }, ...]
   */
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
