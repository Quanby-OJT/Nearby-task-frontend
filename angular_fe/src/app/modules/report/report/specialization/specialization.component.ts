import { Component } from '@angular/core';
import { NgApexchartsModule } from 'ng-apexcharts';
import { ApexOptions } from 'ng-apexcharts';

@Component({
  selector: 'app-specialization',
  standalone: true,
  imports: [NgApexchartsModule],
  templateUrl: './specialization.component.html',
  styleUrls: ['./specialization.component.scss']
})
export class SpecializationComponent {
  chartOptions: ApexOptions = {
    series: [44, 55, 13, 43, 22],
    chart: {
      type: 'pie',
      height: 350
    },
    labels: ['Team A', 'Team B', 'Team C', 'Team D', 'Team E'],
    colors: ['#8586EC', '#4CAF50', '#FFC107', '#FF5722', '#2196F3'],
    responsive: [{
      breakpoint: 480,
      options: {
        chart: {
          width: 200
        },
        legend: {
          position: 'bottom'
        }
      }
    }],
    legend: {
      position: 'bottom'
    }
  };
}
