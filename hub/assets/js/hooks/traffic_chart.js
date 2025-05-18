let TrafficChart = {
  mounted() {
    const ctx = document.getElementById("trafficCanvas").getContext("2d");
    const data = this.getDataFromAssigns();
    this.chart = new Chart(ctx, {
      type: 'line',
      data: {
        labels: data.timestamps,
        datasets: [
          {
            label: 'Вхідний трафік',
            data: data.bytes_in,
            borderColor: 'blue',
            fill: false
          },
          {
            label: 'Вихідний трафік',
            data: data.bytes_out,
            borderColor: 'red',
            fill: false
          }
        ]
      },
      options: { responsive: true }
    });
  },

  updated() {
    const data = this.getDataFromAssigns();
    this.chart.data.labels = data.timestamps;
    this.chart.data.datasets[0].data = data.bytes_in;
    this.chart.data.datasets[1].data = data.bytes_out;
    this.chart.update();
  },

  getDataFromAssigns() {
    // Дані передаються з LiveView як JSON у data-атрибутах або через socket assigns
    // Тут приклад - отримати дані з елементу
    const el = this.el;
    return {
      timestamps: JSON.parse(el.dataset.timestamps),
      bytes_in: JSON.parse(el.dataset.bytesIn),
      bytes_out: JSON.parse(el.dataset.bytesOut)
    };
  }
};

export default TrafficChart;
