import ApplicationChartController from 'controllers/application_chart_controller'
// import consumer from 'consumer'

export default class extends ApplicationChartController {
  chartOptions () {
    const baseOptions = super.chartOptions()
    baseOptions.chart.type = 'bar'
    return baseOptions
  }

  updateSeries (data) {
    this.chart.updateSeries(data, true)
  }

  // connect () {
  //   this.chart = new Apexcharts(this.element, this.chartOptions())
  //   this.chart.render()
    // const controller = this
    // consumer.subscriptions.create({ channel: 'RailsObservatory::ChartChannel', series: this.seriesOptionsValue }, {
    //   connected () {
    //     this.perform('init')
    //   },
    //   received (data) {
    //     controller.updateSeries(data)
    //   }
    // })
  // }
}