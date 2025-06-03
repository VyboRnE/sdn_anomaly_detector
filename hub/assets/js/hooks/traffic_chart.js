import ApexCharts from "apexcharts";

let Hooks = {};

Hooks.TrafficChart = {
  mounted() {
    // Парсимо дані з data-атрибута (передані з LiveView)
    const data = JSON.parse(this.el.dataset.chart);

    const options = {
      chart: {
        type: 'line',
        height: 350,
        toolbar: {
          show: true
        }
      },
      series: [{
        name: 'Трафік',
        data: data.values
      }],
      xaxis: {
        categories: data.timestamps,
        labels: {
          rotate: -45,
          datetimeFormatter: {
            year: 'yyyy',
            month: "MMM 'yy",
            day: 'dd MMM',
            hour: 'HH:mm'
          }
        }
      },
      stroke: {
        curve: 'smooth'
      }
    };

    this.chart = new ApexCharts(this.el, options);
    this.chart.render();
  },

  destroyed() {
    if (this.chart) {
      this.chart.destroy();
    }
  }
};

export default Hooks;
