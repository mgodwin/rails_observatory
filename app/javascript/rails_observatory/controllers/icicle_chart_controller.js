import ApplicationChartController from 'controllers/application_chart_controller'
import merge from 'lodash.merge'

export default class extends ApplicationChartController {
  chartOptions () {
    return merge(super.chartOptions(), {
      chart: {
        type: 'rangeBar',
        height: 300,
        events: {
          dataPointSelection: (event, chartContext, config) => {
            console.log('dataPointSelection', event, chartContext, config)
            this.dispatch('selected', {
              detail: {
                ...config.w.config.series[config.seriesIndex].data[config.dataPointIndex]
              }
            })
          }
        },
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
        formatter: (seriesName, opts)=> {

          const seriesSelfTime = this.initialDataValue[opts.seriesIndex].data.reduce((acc, val) => {
            return acc + val['event_self_time']
          }, 0)
          // console.log(controller.series()[opts.seriesIndex].name, controller.series()[opts.seriesIndex].data);
          const totalSelfTime = this.initialDataValue.reduce((acc, val) => {
            return acc + val.data.reduce((acc, val) => {
              return acc + val['event_self_time']
            }, 0)
          }, 0)
          const percent = seriesSelfTime / totalSelfTime * 100
          return `${seriesName} <span class="percent">${seriesSelfTime.toFixed(1)}ms <div class="bar"><div  style="width:${percent.toFixed(1)}%"></div></div></span> `
        },
        itemMargin: {
          horizontal: '14'
        }
      },
      dataLabels: {
        enabled: true,
        formatter: (value, { seriesIndex, dataPointIndex, w }) => {
          if (value === null || value === undefined) return '';
          const dataPoint = this.initialDataValue[seriesIndex].data[dataPointIndex];
          return `${dataPoint.event_name} (${(value[1] - value[0]).toFixed(2)}ms)`
        },
        offsetX: 4,
        textAnchor: 'start'
      },
      theme: {
        palette: 'palette6',
      },
      stroke: {
        width: 2,
        curve: 'straight'
      }
    })
  }
}


