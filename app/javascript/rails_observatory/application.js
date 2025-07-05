import '@hotwired/turbo-rails'
import 'controllers'

window.Apex = {
  chart: {
    foreColor: '#fff',
    toolbar: {
      show: false
    },
  },
  // colors: ["#7209b7"],
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
    width: 2,
    curve: 'straight'
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