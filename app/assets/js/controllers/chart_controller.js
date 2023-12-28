import {Controller} from "@hotwired/stimulus";
import Apexcharts from "apexcharts";

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
    return {
      chart: {
        id: this.element.id,
        group: this.groupValue,
        type: this.typeValue,
        height: 250,
      },
      title: {
        text: this.element.dataset.chartName,
      },
      series: this.series(),
      xaxis: {
        min: this.startXValue,
        max: this.endXValue,
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