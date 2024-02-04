import {Controller} from "@hotwired/stimulus";
import Apexcharts from "apexcharts";

const icicleChartOptions = function(controller) {
  return {
    chart: {
      id: controller.element.id,
      group: controller.groupValue,
      type: 'rangeBar',
      height: 300,
      events: {
        dataPointSelection: function(event, chartContext, config) {
          controller.dispatch('selected', {detail: {
              ...config.w.config.series[config.seriesIndex].data[config.dataPointIndex]
            }})
        }
      },
    },
    title: {
      text: controller.element.dataset.chartName,
    },
    plotOptions: {
      bar: {
        horizontal: true,
        rangeBarGroupRows: true,
        dataLabels: {
          position: 'bottom'
        },
        // barHeight: '80%'
      }
    },
    series: controller.series(),

    xaxis: {

      type: 'numeric',
      position: 'top',
      axisTicks: {
        show: true
      },
      tooltip: {
        enabled: true,
      }
    },
    yaxis: {
      labels: {
        show: false,

      },

    },
    tooltip: {
      x: {
        formatter: function (value, obj) {
          if (obj) {
            return obj.w.config.series[obj.seriesIndex].data[obj.dataPointIndex].event_name
          } else {
            return value + 'ms'

          }
        }
      },
    },
    legend: {
      position: 'right',
      showForSingleSeries: true,
      formatter: function (seriesName, opts) {

        const seriesSelfTime = controller.series()[opts.seriesIndex].data.reduce((acc, val) => {
          return acc + val['event_self_time']
        }, 0)
        console.log(controller.series()[opts.seriesIndex].name, controller.series()[opts.seriesIndex].data);
        const totalSelfTime = controller.series().reduce((acc, val) => { return acc + val.data.reduce((acc, val) => { return acc + val['event_self_time'] }, 0) }, 0)
        const percent = seriesSelfTime / totalSelfTime * 100
        return `${seriesName} <span class="percent">${seriesSelfTime.toFixed(1)}ms <div class="bar"><div  style="width:${percent.toFixed(1)}%"></div></div></span> `
      },
      itemMargin: {
        horizontal: '14'
      }
    },
    dataLabels: {
      enabled: true,
      formatter: function (value, {seriesIndex, dataPointIndex, w}) {
        return `${w.config.series[seriesIndex].data[dataPointIndex].event_name} (${(value[1] - value[0]).toFixed(2)}ms)`
      },
      offsetX: 0,
      textAnchor: 'start'
    },
    theme: {
      palette: 'palette6',
    },
    stroke: {
      width: 2,
      curve: 'straight'
    }
  }

}

const defaultOptions = function(controller) {
  return {
    chart: {
      id: controller.element.id,
      group: controller.groupValue,
      type: controller.typeValue,
      height: 250,
    },
    title: {
      text: controller.element.dataset.chartName,
    },
    series: controller.series(),
    xaxis: {
      min: controller.startXValue,
      max: controller.endXValue,
      type: 'datetime',
    },
    tooltip: {
      x: {
        format: 'dd MMM yyyy HH:mm'
      },
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
        color: '#0c8be8',
        shadeTo: 'dark',
        shadeIntensity: 0.65
      }
    },
    stroke: {
      width: 2,
      curve: 'straight'
    }
  }

}

export class ChartController extends Controller {
  static targets = ["chart", "data"]

  static values = {
    type: String,
    group: String,
    palette: String,
    startX: Number,
    endX: Number,
  }

  chartOptions() {
    switch (this.typeValue) {
      case 'icicle':
        return icicleChartOptions(this)
      default:
        return defaultOptions(this)
    }
  }

  series() {
    return this.dataTargets.map((target) => ({
      name: target.dataset.seriesName,
      data: JSON.parse(target.innerHTML)
    }));
  }

  connect() {
    this.chart = new Apexcharts(this.chartTarget, this.chartOptions())
    this.chart.render();
  }
}