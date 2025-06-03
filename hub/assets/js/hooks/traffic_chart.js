import ApexCharts from "apexcharts";

let Hooks = {};

// 1. Трафік і аномалії у часі
Hooks.TrafficAnomalyChart = {
  mounted() {
    const data = JSON.parse(this.el.dataset.chart);

    const options = {
      chart: {
        type: 'line',
        height: 350,
        toolbar: { show: true }
      },
      series: [
        {
          name: 'Загальна кількість пакетів',
          data: data.total_packets,
          type: 'line',
          stroke: { curve: 'smooth' },
          color: '#2E86AB',
          yAxisIndex: 0 // Ліва вісь
        },
        {
          name: 'Кількість аномалій',
          data: data.anomaly_flags,
          type: 'line',
          stroke: { curve: 'straight' },
          color: '#FF4560',
          yAxisIndex: 1, // Права вісь
          markers: {
            size: 5,
            colors: ['#FF4560'],
            strokeColors: '#fff',
            strokeWidth: 2
          }
        }
      ],
      xaxis: {
        categories: data.categories,
        type: 'datetime',
        labels: {
          rotate: -45,
          format: 'yyyy-MM-dd HH:mm'
        }
      },
      yaxis: [
        {
          title: {
            text: 'Пакети'
          },
          labels: {
            style: {
              colors: '#2E86AB'
            }
          }
        },
        {
          opposite: true,
          title: {
            text: 'Аномалії'
          },
          labels: {
            style: {
              colors: '#FF4560'
            }
          }
        }
      ],
      tooltip: {
        shared: true,
        intersect: false,
        x: {
          format: 'yyyy-MM-dd HH:mm'
        }
      }
    };

    this.chart = new ApexCharts(this.el, options);
    this.chart.render();
  },

  destroyed() {
    if (this.chart) this.chart.destroy();
  }
};

// 2. Розподіл протоколів (stacked area)
Hooks.ProtocolDistributionChart = {
  mounted() {
    const data = JSON.parse(this.el.dataset.chart);

    const options = {
      chart: {
        type: 'area',
        height: 350,
        stacked: true,
        toolbar: { show: true }
      },
      series: [
        { name: 'TCP', data: data.tcp, color: '#1f77b4' },
        { name: 'UDP', data: data.udp, color: '#ff7f0e' },
        { name: 'ICMP', data: data.icmp, color: '#2ca02c' }
      ],
      xaxis: {
        categories: data.categories,
        type: 'datetime',
        labels: { rotate: -45, format: 'yyyy-MM-dd HH:mm' }
      },
      tooltip: { x: { format: 'yyyy-MM-dd HH:mm' } }
    };

    this.chart = new ApexCharts(this.el, options);
    this.chart.render();
  },

  destroyed() {
    if (this.chart) this.chart.destroy();
  }
};

// 3. Порівняння аномалій CUSUM та Isolation Forest (лінії)
Hooks.AnomalyComparisonChart = {
  mounted() {
    const data = JSON.parse(this.el.dataset.chart);

    const options = {
      chart: {
        type: 'line',
        height: 350,
        toolbar: { show: true }
      },
      series: [
        {
          name: 'CUSUM аномалія',
          data: data.cusum,
          color: '#d62728',
          type: 'line',
          stroke: { curve: 'smooth' }
        },
        {
          name: 'Isolation Forest аномалія',
          data: data.isolation,
          color: '#9467bd',
          type: 'line',
          stroke: { curve: 'smooth' }
        }
      ],
      xaxis: {
        categories: data.categories,
        type: 'datetime',
        labels: { rotate: -45, format: 'yyyy-MM-dd HH:mm' }
      },
      tooltip: { x: { format: 'yyyy-MM-dd HH:mm' } }
    };

    this.chart = new ApexCharts(this.el, options);
    this.chart.render();
  },

  destroyed() {
    if (this.chart) this.chart.destroy();
  }
};

// 4. Топ цільових портів (горизонтальна стовпчикова діаграма)
Hooks.TopPortsChart = {
  mounted() {
    const data = JSON.parse(this.el.dataset.chart);

    const options = {
      chart: {
        type: 'bar',
        height: 350,
        toolbar: { show: true }
      },
      series: [{
        name: 'Кількість',
        data: data.counts
      }],
      plotOptions: {
        bar: {
          horizontal: true,
          barHeight: '50%'
        }
      },
      xaxis: {
        categories: data.ports,
        labels: {
          rotate: 0
        }
      },
      tooltip: {}
    };

    this.chart = new ApexCharts(this.el, options);
    this.chart.render();
  },

  destroyed() {
    if (this.chart) this.chart.destroy();
  }
};

// 5. Унікальні IP у часі (лінійний графік)
Hooks.UniqueIpsChart = {
  mounted() {
    const data = JSON.parse(this.el.dataset.chart);

    const options = {
      chart: {
        type: 'line',
        height: 350,
        toolbar: { show: true }
      },
      series: [{
        name: 'Унікальні IP-адреси',
        data: data.unique_src_ips,
        color: '#17becf'
      }],
      xaxis: {
        categories: data.categories,
        type: 'datetime',
        labels: { rotate: -45, format: 'yyyy-MM-dd HH:mm' }
      },
      tooltip: { x: { format: 'yyyy-MM-dd HH:mm' } }
    };

    this.chart = new ApexCharts(this.el, options);
    this.chart.render();
  },

  destroyed() {
    if (this.chart) this.chart.destroy();
  }
};

export default Hooks;
