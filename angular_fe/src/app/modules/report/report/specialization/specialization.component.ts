import { Component, OnInit } from '@angular/core';
import { NgApexchartsModule } from 'ng-apexcharts';
import { ReportService } from '../../../../services/reportANDanalysis.services';
import { HttpClientModule } from '@angular/common/http';

@Component({
  selector: 'app-specialization',
  standalone: true,
  imports: [NgApexchartsModule, HttpClientModule],
  templateUrl: './specialization.component.html',
  styleUrls: ['./specialization.component.scss']
})
export class SpecializationComponent implements OnInit {
  rankedSpecializations: { specialization: string, count: number }[] = [];
  monthlyTrends: { [key: string]: { [key: string]: number } } = {};
  chartSeries: { name: string, data: number[] }[] = [];
  chartCategories: string[] = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul'];

  constructor(private reportService: ReportService) {}

  ngOnInit(): void {
    this.fetchSpecializations();
  }

  fetchSpecializations(): void {
    this.reportService.getSpecialization().subscribe({
      next: (response: {success: boolean, rankedSpecializations: {specialization: string, count: number}[], monthlyTrends: {[key: string]: {[key: string]: number}}}) => {
        if (response.success) {
          this.rankedSpecializations = response.rankedSpecializations;
          this.monthlyTrends = response.monthlyTrends;
          this.updateChart();
        }
      },
      error: (error: any) => {
        console.error('Error fetching specialization data:', error);
      }
    });
  }

  updateChart(): void {
    // Prepare chart series data based on ranked specializations
    this.chartSeries = this.rankedSpecializations.map(spec => ({
      name: spec.specialization,
      data: this.chartCategories.map(month => this.monthlyTrends[spec.specialization]?.[month] || 0)
    }));
  }

  // Example of using the service
  getData() {
    this.reportService.getSpecialization().subscribe((data: any) => {
      // Handle the data here
    });
  }
}