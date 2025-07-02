import ApplicationChartController from 'controllers/application_chart_controller'

export default class extends ApplicationChartController {
  chartOptions () {
    const baseOptions = super.chartOptions()
    baseOptions.chart.type = 'area'
    baseOptions.legend = { show: false }
    return baseOptions
  }
}