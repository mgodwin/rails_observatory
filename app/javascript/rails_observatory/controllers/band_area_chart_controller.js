import ApplicationChartController from 'controllers/application_chart_controller'

// Renders a latency chart with a variance band: a translucent rangeArea
// spanning avg ± std.p with the mean line drawn on top. Expects initialData
// to be a two-element series array ([rangeArea band, line]) as produced by
// the `latency_band_series` helper.
export default class extends ApplicationChartController {
  chartOptions () {
    const baseOptions = super.chartOptions()
    baseOptions.chart.type = 'rangeArea'
    baseOptions.legend = { show: false }
    // Gray, dashed-outline variance band (index 0); accent mean line (index 1).
    baseOptions.colors = ['#9ca3af', '#008FFB']
    baseOptions.fill = { opacity: [0.15, 1] }
    baseOptions.stroke = { width: [1.5, 2], dashArray: [4, 0], curve: 'straight' }
    baseOptions.tooltip = { ...baseOptions.tooltip, shared: true, intersect: false }
    return baseOptions
  }
}
