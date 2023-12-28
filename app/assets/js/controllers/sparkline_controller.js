import {ChartController} from "./chart_controller";

export class SparklineController extends ChartController {

  maxSeries() {
    return this.series()[0].data.reduce((a, b) => Math.max(a, b[1]), 0)
  }

  chartOptions() {
    return {
      chart: {
        type: this.typeValue,
        height: 50,
        sparkline: {
          enabled: true
        },
      },
      colors: ["#7209b7"],
      series: this.series(),
      xaxis: {
        min: this.startXValue,
        max: this.endXValue,
        axisBorder: {
          show: true,
          height: 2,
          color: 'var(--divider)',
        },
      },
      yaxis: {
        max: this.maxSeries(),
      },
      fill: {
        gradient: {
          enabled: true,
          opacityFrom: 0.55,
          opacityTo: 0
        }
      },
      theme: {
        monochrome: {
          enabled: true,
          color: '#ba181b',
          shadeTo: 'dark',
          shadeIntensity: 0.65
        }
      },
      tooltip: {
        fixed: {
          enabled: false
        },
        x: {
          show: true,
        },
        y: {
          title: {
            formatter: (seriesName) => 'Occurrences',
          }
        },
        marker: {
          show: false
        },


      },

      stroke: {
        width: 1,
        curve: 'straight'
      },
    }
  }
}