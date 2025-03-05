import { Component, viewChild, ViewChild } from '@angular/core';
import { ChartComponent, NgApexchartsModule } from 'ng-apexcharts';
import { ApexNonAxisChartSeries, ApexChart, ApexResponsive, ApexLegend } from 'ng-apexcharts';

export type ChartOptions = {
  series: ApexNonAxisChartSeries;
  chart: ApexChart;
  labels: string[];
  responsive: ApexResponsive[];
  legend: ApexLegend;
};

@Component({
  selector: '[user-chart-card]',
  imports: [NgApexchartsModule],
  templateUrl: './user-chart-card.component.html',
  styleUrl: './user-chart-card.component.css',
})
export class UserChartCardComponent {
  @ViewChild('chart') chart!: ChartComponent;
  public chartOptions: ChartOptions;

  constructor() {
    this.chartOptions = {
      series: [50, 30, 15, 5],
      chart: {
        type: 'pie',
      },
      labels: ['Users', 'Moderators', 'Taskers', 'Clients'],
      responsive: [
        {
          breakpoint: 480,
          options: {
            chart: {
              width: 400,
            },
            legend: {
              position: 'bottom',
            },
          },
        },
      ],
      legend: {
        position: 'right',
      },
    };
  }
}
