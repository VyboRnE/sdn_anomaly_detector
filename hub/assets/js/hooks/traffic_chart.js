import ApexCharts from "apexcharts";

let Hooks = {};

// Загальна функція для ініціалізації та оновлення графіка
function initializeChart(el, data, optionsBuilder) {
  const chartData = JSON.parse(data);
  const options = optionsBuilder(chartData);

  if (el._apexChart) {
    el._apexChart.updateOptions(options);
  } else {
    el._apexChart = new ApexCharts(el, options);
    el._apexChart.render();
  }
}

// Трафік і аномалії
Hooks.TrafficAnomalyChart = {
  mounted() {
    initializeChart(this.el, this.el.dataset.chart, (data) => {
      const hasAnomalies = data.anomaly_flags.some(value => value > 0);

      const series = [
        {
          name: 'Загальна кількість пакетів',
          data: data.total_packets,
          type: 'line',
          stroke: { curve: 'smooth' },
          color: '#2E86AB',
          yAxisIndex: 0
        }
      ];

      if (hasAnomalies) {
        series.push({
          name: 'Кількість аномалій',
          data: data.anomaly_flags,
          type: 'bar',
          color: '#FF4560',
          yAxisIndex: 1,
          markers: {
            size: 1,
            colors: ['#FF4560'],
            strokeColors: '#fff',
            strokeWidth: 1
          }
        });
      }

      const yaxis = [
        {
          title: { text: 'Пакети' },
          labels: { style: { colors: '#2E86AB' } }
        }
      ];

      if (hasAnomalies) {
        yaxis.push({
          opposite: true,
          show: false, // приховуємо шкалу осі
          labels: { show: false },
          axisBorder: { show: false },
          axisTicks: { show: false }
        });
      }

      return {
        chart: { type: 'line', height: 350, toolbar: { show: true } },
        series: series,
        xaxis: {
          categories: data.categories,
          type: 'datetime',
          labels: {
            rotate: -45,
            format: 'yyyy-MM-dd HH:mm'
          }
        },
        yaxis: yaxis,
        tooltip: {
          shared: true,
          intersect: false,
          x: { format: 'yyyy-MM-dd HH:mm' }
        },
        plotOptions: hasAnomalies ? {
          bar: {
            columnWidth: '20%',
            barHeight: '20%'
          }
        } : {}
      };
    });
  },
  updated() {
    this.mounted();
  },
  destroyed() {
    if (this.el._apexChart) this.el._apexChart.destroy();
  }
};

// Розподіл протоколів
Hooks.ProtocolDistributionChart = {
  mounted() {
    initializeChart(this.el, this.el.dataset.chart, (data) => ({
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
    }));
  },
  updated() {
    this.mounted();
  },
  destroyed() {
    if (this.el._apexChart) this.el._apexChart.destroy();
  }
};

// Порівняння аномалій
Hooks.AnomalyComparisonChart = {
  mounted() {
    initializeChart(this.el, this.el.dataset.chart, (data) => ({
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
    }));
  },
  updated() {
    this.mounted();
  },
  destroyed() {
    if (this.el._apexChart) this.el._apexChart.destroy();
  }
};

// Топ портів
Hooks.TopPortsChart = {
  mounted() {
    initializeChart(this.el, this.el.dataset.chart, (data) => ({
      chart: {
        type: 'bar',
        height: 350,
        toolbar: { show: true }
      },
      series: [{ name: 'Кількість', data: data.counts }],
      plotOptions: {
        bar: {
          horizontal: true,
          barHeight: '50%'
        }
      },
      xaxis: {
        categories: data.ports,
        labels: { rotate: 0 }
      },
      tooltip: {}
    }));
  },
  updated() {
    this.mounted();
  },
  destroyed() {
    if (this.el._apexChart) this.el._apexChart.destroy();
  }
};

// Унікальні IP
Hooks.UniqueIpsChart = {
  mounted() {
    initializeChart(this.el, this.el.dataset.chart, (data) => ({
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
    }));
  },
  updated() {
    this.mounted();
  },
  destroyed() {
    if (this.el._apexChart) this.el._apexChart.destroy();
  }
};

export default Hooks;
