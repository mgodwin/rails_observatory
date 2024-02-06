import ApexCharts from 'apexcharts'
import * as Stimulus from "@hotwired/stimulus"
import {controllers} from "./controllers"

window.Apex = {
  chart: {
    foreColor: '#fff',
    animations: {
      enabled: false
    },
    toolbar: {
      show: false
    },
  },
  // colors: ["#7209b7"],
  grid: {
    borderColor: 'var(--divider)',
    strokeDashArray: 4,
    xaxis: {
      lines: {
        show: true
      }
    },
    yaxis: {
      lines: {
        show: true
      }
    },
    padding: {
      top: 0,
      right: 0,
      bottom: 0,
      left: 0
    },
  },
  title: {
    align: 'left',
    offsetY: 20,
    style: {
      fontSize: '1rem',
      fontWeight: 500,
      fontFamily: 'inherit',
      color: 'var(--white)'
    }
  },
  stroke: {
    width: 3,
    curve: 'straight'
  },
  dataLabels: {
    enabled: false
  },
  tooltip: {
    x: {
      format: 'dd MMM yyyy HH:mm'
    },
    theme: 'dark',
  },
  xaxis: {
    type: 'datetime',
    axisBorder: {
      show: false,
    },
    axisTicks: {
      show: false
    },
    crosshairs: {
      width: 1
    },
  },
  yaxis: {
    decimalsInFloat: 0,
    labels: {
       offsetX: -10,
      // align: 'left',
    },
    axisTicks: {
      show: false
    },
  },
}
window.Stimulus = Stimulus

const application = Stimulus.Application.start()

Object.entries(controllers).forEach(([key, controller]) => {
  application.register(key, controller)
})