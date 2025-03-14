import { Component, OnInit, OnDestroy } from '@angular/core';
import { AngularSvgIconModule } from 'angular-svg-icon';
import { NgApexchartsModule } from 'ng-apexcharts';
import { ChartOptions } from '../../../../../shared/models/chart-options';

@Component({
  selector: '[nft-chart-card]',
  templateUrl: './nft-chart-card.component.html',
  imports: [AngularSvgIconModule, NgApexchartsModule],
  standalone: true
})
export class RevenueChart implements OnInit, OnDestroy {
  public chartOptions: Partial<ChartOptions>;

  constructor() {
    // Change aas soon data are available to display
    const completedTasks = [2, 3, 2, 3, 4, 3, 4, 3, 5, 4, 5, 4, 5, 6, 7];
    const timeLabels = ['9AM', '10AM', '11AM', '12PM', '1PM', '2PM', '3PM', '4PM', '5PM', '6PM', '7PM', '8PM', '9PM', '10PM', '11PM'];

    this.chartOptions = {
      series: [{
        name: 'Completed Tasks', 
        data: completedTasks    
      }],
      chart: {
        type: 'area',   
        height: 150,     
        toolbar: {
          show: false   
        },
        sparkline: {
          enabled: true 
        }
      },
      dataLabels: {
        enabled: false  
      },
      fill: {
        type: 'gradient', 
        gradient: {
          shadeIntensity: 1,
          opacityFrom: 0.4,
          opacityTo: 0.2,
          stops: [15, 120, 100] 
        }
      },
      stroke: {
        curve: 'smooth',
        width: 2,       
        colors: ['#3B82F6'] 
      },
      xaxis: {
        categories: timeLabels
      },
      yaxis: {
        show: false 
      },
      grid: {
        show: false 
      },
      tooltip: {
        enabled: true, 
        y: {
          formatter: (val: number) => `${val}` 
        }
      },
      colors: ['#3B82F6'] 
    };
  }

  ngOnInit(): void {}

  ngOnDestroy(): void {}
}