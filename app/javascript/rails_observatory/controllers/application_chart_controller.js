import { Controller } from '@hotwired/stimulus'
import Apexcharts from 'apexcharts'

export default class extends Controller {

  static values = {
    group: String,
    palette: String,
    name: String,
    stacked: { type: Boolean, default: false },
    stackedType: { type: String, default: 'normal' },
    initialData: Array,
  }

  connect () {
    this.chart = new Apexcharts(this.element, this.chartOptions())
    this.chart.render()
  }

  disconnect () {
    this.chart.destroy()
  }

  extractRange () {

  }

  chartOptions () {
    return {
      chart: {
        id: this.element.id,
        group: this.groupValue,
        height: 250,
        stacked: this.stackedValue,
        stackType: this.stackedTypeValue,
        animations: {
          enabled: false,
          speed: 300,
          dynamicAnimation: {
            enabled: false
          }
        },
        zoom: {
          allowMouseWheelZoom: false,
        },
        events: {
          zoomed: (chartContext, { xaxis, yaxis }) => {
            console.log({ chartContext })
            // window.location.href = `?ts=${Math.round(xaxis.min / 1000)}&te=${Math.round(xaxis.max / 1000)}`
            // this.chart.resetSeries()
            // controller.dispatch('zoom', { detail: { ...xaxis } })
          }
        }
      },
      dataLabels: { enabled: false },
      title: {
        text: this.nameValue,
      },
      series: this.initialDataValue,
      xaxis: {
        // min: controller.startXValue,
        // max: controller.endXValue,
        type: 'datetime',
        labels: {
          datetimeUTC: false,
          datetimeFormatter: {
            year: 'yyyy',
            month: 'MMM \'yy',
            day: 'dd MMM',
            hour: 'H',
            minute: 'HH:mm',
            second: 'HH:mm',
          },
        },
      },
      tooltip: {
        // intersect: false,
        x: {
          format: 'dd MMM yyyy HH:mm'
        },
      },
      noData: {
        text: 'No Data Available',
      },
      fill: {
        gradient: {
          enabled: true,
          opacityFrom: 0.55,
          opacityTo: 0
        }
      },
      stroke: {
        width: 2,
        curve: 'straight'
      },
    }
  }
}